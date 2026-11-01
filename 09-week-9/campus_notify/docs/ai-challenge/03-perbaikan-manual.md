# Perbaikan Manual atas Draf AI

Dua jenis perbaikan: yang **dipaksa** analyzer, dan yang **ditemukan sendiri**
karena analyzer tidak bisa melihatnya. Yang kedua itu inti codelab ini.

---

## A. Dipaksa analyzer (kode tidak jalan tanpa ini)

### A1. `flutter_local_notifications` 22 mengubah signature

Draf memakai posisi argumen seperti codelab. Di versi 22 semua jadi named:

```dart
// draf (gagal)
await _local.show(
  message.hashCode, title, body, details,
  payload: route,
);

// perbaikan
await _local.show(
  id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
  title: title,
  body: body,
  notificationDetails: details,
  payload: route,
);
```

`initialize()` juga berubah dari `initialize(settings, onDid...)` menjadi
`initialize(settings: settings, onDid...: ...)`.

**Catatan tambahan:** `id` draf memakai `message.hashCode`. Itu bertabrakan
untuk pesan berbeda yang kebetulan punya hash sama, dan bisa membuat banner
baru menimpa banner lama. Diganti timestamp.

### A2. `firebase_messaging` 17: `getToken`/`onTokenRefresh` deprecated

```dart
// draf
final token = await FirebaseMessaging.instance.getToken();
FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

// perbaikan
FirebaseMessaging.instance.onRegistered.listen(_sendTokenToBackend);
await FirebaseMessaging.instance.register();
```

Konsekuensi yang harus disadari: nilai yang diterima adalah **Firebase
Installation ID**, bukan FCM registration token gaya lama. Kontrak backend
(`POST /devices` dengan field `fcm_token`) sengaja tidak diubah; kalau backend
memakai FCM HTTP v1, nilai ini dipakai sebagai `message.token`.

### A3. `DioExceptionType` punya case baru

`transformTimeout` ditambahkan di dio 5.11. Switch jadi non-exhaustive:

```dart
case DioExceptionType.connectionTimeout:
case DioExceptionType.sendTimeout:
case DioExceptionType.receiveTimeout:
case DioExceptionType.transformTimeout:   // tambahan
  return 'Server terlalu lama merespons. Coba lagi.';
```

### A4. Lint `prefer_initializing_formals`

Parameter konstruktor yang langsung disalin ke field privat diberi nama field:

```dart
// draf
PushService({required Dio dio}) : _dio = dio;

// perbaikan
PushService({required Dio httpClient}) : _dio = httpClient;
```

### A5. `unused_import`

`routes.dart` diimpor di `main.dart` tetapi tidak dipakai setelah navigasi
dipindah ke `routerProvider`. Dihapus.

---

## B. Ditemukan sendiri (analyzer diam, perilaku salah)

Bagian ini yang harus bisa dijelaskan saat demo.

### B1. Channel notifikasi tidak pernah dibuat

Draf mengandalkan `flutter_local_notifications` membuat channel saat `show()`
pertama. Masalahnya: banner FCM dari background/terminated **tidak** lewat
`show()` — itu ditangani sistem memakai `default_notification_channel_id` dari
AndroidManifest. Bila channel `pengumuman` belum ada, Android 8+ membuang
notifikasinya tanpa pesan error.

Perbaikan: channel dibuat eksplisit saat inisialisasi.

```dart
await android.createNotificationChannel(
  const AndroidNotificationChannel(
    _channelId, 'Pengumuman Kampus',
    description: 'Notifikasi pengumuman dan jadwal kampus',
    importance: Importance.high,
  ),
);
```

Gejalanya di perangkat: "notifikasi kadang muncul, kadang tidak" — tergantung
apakah pengguna pernah membuka aplikasi sampai banner lokal tampil.

### B2. `onTokenRefresh` hanya di-print, tidak dikirim

Checklist codelab menolak ini secara eksplisit. Draf menyediakan
`initFcmToken(onToken: ...)` yang memaksa pemanggil menyuplai callback, tetapi
tidak ada yang menjamin callback itu mengirim ke backend — di praktiknya sering
berakhir `print(token)`.

Perbaikan: pengiriman ada **di dalam** service, bukan diserahkan ke pemanggil.

```dart
Future<void> _sendTokenToBackend(String token) async {
  _set(tokenPreview: maskToken(token), tokenUpdatedAt: DateTime.now());
  await _dio.post(ApiConfig.devicesPath, data: {
    'fcm_token': token,
    'platform': defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
  });
}
```

### B3. Token utuh bisa bocor ke screenshot

Draf tidak punya jalur untuk menampilkan token, jadi saat demo orang menambah
`print(token)` sendiri. Perbaikan: `maskToken()` (12 karakter pertama) dan
halaman Debug yang hanya menampilkan nilai terpotong.

```dart
String maskToken(String token) => token.length <= 12
    ? '${token.substring(0, token.length ~/ 2)}...'
    : '${token.substring(0, 12)}...';
```

### B4. `pendingDeepLink` global tidak pernah dikonsumsi ulang

Draf menyimpan klik banner di variabel global, tetapi hanya membacanya sekali di
`handleTerminated()`. Klik kedua di sesi yang sama diabaikan, dan nilainya tidak
pernah di-reset sehingga bisa memicu navigasi hantu setelah login ulang.

Perbaikan: `DeepLinkBuffer` (provider) dengan `put()`/`take()` — `take()`
mengosongkan nilai, jadi tiap klik hanya dipakai sekali.

### B5. Deep link hilang bila sesi sudah habis

Skenario nyata: pengguna klik notifikasi setelah token kedaluwarsa. Guard route
melempar ke `/login`, route tujuan dibuang, setelah login pengguna mendarat di
beranda dan mengira notifikasinya rusak.

Perbaikan: route ditahan di buffer, lalu dikirim setelah `authStateProvider`
berubah menjadi login.

```dart
ref.listen<AsyncValue<bool>>(authStateProvider, (previous, next) {
  final wasLoggedIn = previous?.value ?? false;
  final isLoggedIn = next.value ?? false;
  if (!wasLoggedIn && isLoggedIn) {
    final pending = ref.read(deepLinkBufferProvider).take();
    if (pending != null) router.go(pending);
  }
});
```

### B6. Payload bertipe salah diloloskan ke router

Draf: `message.data['route'] ?? '/'`. Kalau backend mengirim `route: 3` (angka),
nilainya masuk ke `go()` dan router crash atau membuka path aneh.

Perbaikan: fungsi murni yang memvalidasi tipe dan menormalkan slash.

```dart
String routeFromMessage(Map<String, dynamic> data) {
  final raw = data['route'];
  return normalizeRoute(raw is String ? raw : null);
}
```

Fungsi ini juga yang membuat `routeFromMessage` bisa diuji tanpa Firebase —
sesuai *Refactoring Challenge* nomor 2.

### B7. `getInitialMessage` dipanggil sebelum router siap

Draf memanggil `handleTerminated()` di dalam `main()` sebelum `runApp`. Router
belum ada, jadi `go()` tidak melakukan apa pun. Notifikasi terminated membuka
aplikasi di beranda.

Perbaikan: `attach()` dipanggil **setelah** `runApp` dan router dibuat.

### B8. String rute tersebar

`/login`, `/pengumuman/:id`, dan payload FCM ditulis manual di beberapa tempat.
Satu salah ketik = deep link mati. Perbaikan: `lib/routes.dart` sebagai satu
sumber, dipakai GoRouter dan `AppRoutes.announcement(id)`.

---

## Ringkasan

| # | Temuan | Jenis | Terdeteksi oleh |
| --- | --- | --- | --- |
| A1 | Signature `show`/`initialize` | compile error | analyzer |
| A2 | `getToken`/`onTokenRefresh` deprecated | API usang | analyzer |
| A3 | `transformTimeout` tidak ditangani | compile error | analyzer |
| A4 | `prefer_initializing_formals` | lint | analyzer |
| A5 | `unused_import` | lint | analyzer |
| B1 | Channel notifikasi tidak dibuat | perilaku | uji perangkat |
| B2 | Token tidak dikirim ke backend | perilaku | baca ulang checklist |
| B3 | Token utuh bisa tampil | keamanan | baca ulang checklist |
| B4 | `pendingDeepLink` global | perilaku | baca ulang kode |
| B5 | Deep link hilang saat sesi habis | perilaku | skenario uji |
| B6 | Payload tipe salah diloloskan | ketahanan | unit test |
| B7 | `getInitialMessage` sebelum router | perilaku | uji terminated |
| B8 | String rute tersebar | maintainability | refactor |

Dari 13 temuan, hanya **5** yang dilaporkan analyzer. Delapan sisanya hanya
muncul kalau kode dibaca ulang terhadap checklist dan diuji di perangkat —
persis alasan codelab menyatakan AI tidak boleh jadi penentu akhir.
