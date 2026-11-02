# Praktikum 3 — Catatan Implementasi

Pemetaan tiap butir praktikum ke kode, ditambah alasan teknis di balik
keputusan yang menyimpang dari contoh codelab.

## 1. Background handler wajib top-level

`lib/messaging/push_service.dart`

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // kosong: hanya data ringan, tanpa BuildContext / Riverpod
}
```

- Fungsi top-level, bukan method kelas. Firebase menjalankannya di isolate
  terpisah; method kelas tidak akan ditemukan di isolate itu.
- `@pragma('vm:entry-point')` mencegah AOT compiler membuang fungsi karena
  tidak dipanggil langsung dari kode Dart.
- Pendaftaran dilakukan di `main()` **hanya bila** `Firebase.initializeApp()`
  berhasil, supaya aplikasi tidak crash saat `google-services.json` belum ada.

## 2. Tiga handler

| Handler | State | Perilaku |
| --- | --- | --- |
| `FirebaseMessaging.onMessage` | Foreground | Sistem tidak menampilkan banner → ditampilkan manual lewat `flutter_local_notifications` |
| `FirebaseMessaging.onMessageOpenedApp` | Background | Banner sistem tampil otomatis, klik masuk ke `data.route` |
| `FirebaseMessaging.instance.getInitialMessage()` | Terminated | Dipanggil setelah router siap; hasilnya diteruskan ke `data.route` |

Klik banner lokal (foreground → background) ditangani
`onDidReceiveNotificationResponse`, dan bila aplikasi dibuka dari banner lokal
saat terminated dipakai `getNotificationAppLaunchDetails()`.

### Deep link saat sesi habis

`lib/providers/app_providers.dart` — `DeepLinkBuffer`

Klik notifikasi ketika token sudah kedaluwarsa akan ditolak guard route.
Route-nya disimpan dulu, lalu dikirim setelah login berhasil. Tanpa buffer ini
pengguna mendarat di beranda dan mengira notifikasinya rusak.

## 3. Payload gabungan

Selalu `notification + data`:

- `notification.title` / `notification.body` → teks yang dibaca manusia.
- `data.route` → tujuan klik.
- `data.id` → id pengumuman, dipakai halaman detail.

Parsing dipisah ke fungsi murni `routeFromMessage(Map<String, dynamic>)` supaya
bisa diuji tanpa Firebase, dan menormalkan `pengumuman/3` (tanpa slash) menjadi
`/pengumuman/3`. Payload dengan `route` bertipe bukan string jatuh ke `/`, bukan
dipaksa menjadi path aneh.

## 4. Topik

`subscribeToTopic('pengumuman-kampus')` dipanggil setelah izin diberikan, dan
statusnya tampil di halaman Debug. Tombol berhenti berlangganan disediakan untuk
membuktikan `unsubscribeFromTopic` juga bekerja.

Aturan yang dipegang: topik untuk broadcast, token/ID perangkat untuk pesan
personal.

## Catatan versi paket

`firebase_messaging` 17 menandai `getToken()` dan `onTokenRefresh` sebagai
**deprecated** dan menggantinya dengan `register()` + `onRegistered`. Nilai yang
diterima adalah Firebase Installation ID, yang juga menjadi target kirim
langsung untuk instance aplikasi. Kode memakai API baru; kode codelab yang masih
memakai `getToken()` tetap jalan, tetapi akan memunculkan peringatan analyzer.

Konsekuensi praktis: endpoint `POST /devices` menerima `fcm_token` berisi ID
tersebut. Bila backend memakai FCM HTTP v1, field `fid` pada request kirim diisi
nilai yang sama.

### Syarat manifest yang mudah terlewat

`register()` **tidak** jalan hanya dengan menambah dependency. Firebase Android
SDK melempar `IllegalStateException` bila flag berikut tidak ada di manifest:

```xml
<meta-data
    android:name="firebase_messaging_installation_id_enabled"
    android:value="true" />
```

Tanpa flag itu, `onRegistered` tidak pernah emit, `_sendTokenToBackend` tidak
pernah dipanggil, dan halaman Debug menampilkan "Gagal registrasi FCM" tanpa
petunjuk penyebabnya. README paket Flutter tidak menyebut flag ini; sumbernya ada
di javadoc `FirebaseMessaging.register()` versi Android. Ini temuan yang **tidak**
terdeteksi analyzer maupun pembacaan ulang kode Dart.

### Registrasi terjadi sebelum login

`attach()` dipanggil di `main()` sebelum sesi ada, jadi kiriman pertama tidak
punya konteks user. Karena itu `PushService.syncDeviceToBackend()` dipanggil
ulang setiap login berhasil (dan saat aplikasi dibuka dengan sesi yang masih
aktif) agar `POST /devices` bisa menyimpan ID atas nama pengguna tersebut.

## Bukti manual yang masih harus diisi

Tabel di `README.md` sengaja dibiarkan berisi instruksi, bukan hasil karangan.
Isi kolom **Hasil** dengan screenshot dan potongan log setelah menguji di
perangkat. Emulator tanpa Google Play Services sering menghasilkan ID null;
gunakan emulator berikon Play Store atau perangkat fisik.
