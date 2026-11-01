# Campus Notify — Praktikum 3: Payload, Tiga App State, Klik dan Topik

Aplikasi Flutter untuk menerima pengumuman kampus lewat Firebase Cloud
Messaging. Fokus praktikum ini adalah **payload gabungan `notification + data`**,
**tiga app state** (foreground, background, terminated), **deep link saat klik**,
dan **topic messaging**.

> Codelab: [Minggu 6 — Authentication, Security & FCM, Praktikum 3](https://jti-polinema.github.io/flutter-codelab/06-minggu-6-authentication-security-fcm/index.html#4)

## Tujuan

- Menjelaskan beda `notification payload` dan `data payload` serta perilakunya
  di tiap app state.
- Memasang background handler sebagai fungsi top-level dengan
  `@pragma('vm:entry-point')`.
- Menangani klik notifikasi dari tiga state dan mengarahkannya ke
  `/pengumuman/:id`.
- Mengelola topik (`subscribe`/`unsubscribe`) untuk pesan broadcast.
- Membuktikan perilaku nyata lewat tabel uji dan screenshot, bukan hanya kode.

## Fitur

| Fitur | Lokasi |
| --- | --- |
| Background handler top-level | `lib/messaging/push_service.dart` |
| Foreground: banner lokal manual | `lib/messaging/push_service.dart` |
| Background diklik: `onMessageOpenedApp` | `lib/messaging/push_service.dart` |
| Terminated: `getInitialMessage` | `lib/messaging/push_service.dart` |
| Klik banner lokal saat terminated | `lib/messaging/push_service.dart` |
| Parsing payload → route (fungsi murni) | `lib/messaging/notification_route.dart` |
| Topik `pengumuman-kampus` | `lib/messaging/push_service.dart` |
| Deep link `/pengumuman/:id` | `lib/routes.dart`, `lib/pages/announcement_page.dart` |
| Halaman Debug (izin, ID terpotong, uji banner) | `lib/pages/debug_page.dart` |
| Login + guard route + token secure storage | `lib/providers/auth_provider.dart`, `lib/data/` |

## Stack

- `firebase_core` 5.x, `firebase_messaging` 17.x
- `flutter_local_notifications` 22.x (banner foreground)
- `go_router` 18.x (deep link), `flutter_riverpod` 3.x (state)
- `dio` 5.x + `flutter_secure_storage` 11.x (auth & token)

## Cara menjalankan

```bash
flutter pub get
flutter run
```

Login memakai email apa pun dan kata sandi minimal 6 karakter (mock auth).

### Android Studio

Project ini sudah disiapkan untuk langsung dijalankan dari Android Studio:
plugin `google-services` dipasang bersyarat, dua run configuration tersedia,
dan build debug mengizinkan HTTP ke API lokal.

1. Buka folder `campus_notify` di Android Studio, tunggu Gradle sync.
2. Buat emulator **ber-Play Store** (wajib untuk FCM).
3. Letakkan `google-services.json` di `android/app/` bila ingin FCM aktif.
4. Pilih run configuration `campus_notify (debug)` → Run.

Panduan lengkap + tabel masalah umum: [`docs/android-studio.md`](docs/android-studio.md).

### Firebase (opsional untuk demo UI)

Praktikum ini butuh Firebase untuk mengirim pesan sungguhan:

1. Buat project di Firebase Console, tambahkan aplikasi Android dengan
   `applicationId = id.polinema.campus_notify`.
2. Unduh `google-services.json` ke `android/app/`.
3. Tambahkan plugin Google Services sesuai dokumentasi FlutterFire, lalu
   `flutter run` ulang.

Tanpa `google-services.json`, aplikasi **tetap bisa dijalankan**: halaman Debug
menampilkan "Firebase belum dikonfigurasi" dan tombol **Kirim notifikasi uji**
masih bisa dipakai untuk membuktikan jalur banner → deep link.

## Payload yang dipakai

Contoh lengkap ada di [`docs/fcm-payload.json`](docs/fcm-payload.json).

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Jadwal kuliah berubah",
      "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
    },
    "data": {
      "route": "/pengumuman/3",
      "id": "3"
    }
  }
}
```

- `notification` → teks yang dibaca manusia. Sistem menampilkannya otomatis saat
  background/terminated, **tidak** saat foreground.
- `data.route` → tujuan deep link. Selalu diterima aplikasi, dipakai saat klik.

## Matriks pengujian tiga app state

Uji dengan payload yang sama di atas. Isi kolom **Hasil** setelah pengujian di
perangkat fisik (emulator tanpa Play Services sering gagal menerima pesan).

| State | Yang diharapkan | Cara uji | Hasil |
| --- | --- | --- | --- |
| Foreground | Banner lokal muncul, klik masuk ke `/pengumuman/3` | Aplikasi terbuka, kirim dari Firebase Console | _isi: screenshot + log_ |
| Background | Banner sistem muncul, klik masuk ke rute yang benar | Tekan Home, kirim, klik banner | _isi: screenshot + log_ |
| Terminated | Aplikasi terbuka ke rute yang benar via `getInitialMessage` | Swipe-close aplikasi, kirim, klik banner | _isi: screenshot + log_ |

Bukti tanpa Firebase (jalur lokal, untuk demo cepat):

| Langkah | Yang dibuktikan |
| --- | --- |
| Debug → **Kirim notifikasi uji** saat aplikasi terbuka | `onMessage` → banner lokal manual |
| Kirim notifikasi uji, tekan Home, klik banner | `onDidReceiveNotificationResponse` → `/pengumuman/3` |
| Kirim notifikasi uji, swipe-close, klik banner | `getNotificationAppLaunchDetails` → `/pengumuman/3` |

Screenshot yang perlu diambil ada di [`screenshots/README.md`](screenshots/README.md).

## Topic messaging

- Topik dipakai untuk **broadcast**: semua mahasiswa, satu kelas, satu UKM.
- Nama topik tanpa spasi: `pengumuman-kampus`.
- Pesan personal (nilai, tagihan) memakai **token/ID perangkat**, bukan topik.

Tombol berlangganan/berhenti ada di halaman Debug. Status topik ikut tampil di
sana.

## Keamanan

- Token auth hanya di `flutter_secure_storage` (`lib/data/token_store.dart`),
  tidak pernah di SharedPreferences.
- Token/ID FCM di layar Debug dipotong 12 karakter pertama
  (`maskToken`), tidak pernah dicetak penuh ke log.
- 401 memicu refresh **sekali** lalu retry; refresh mati → token dihapus dan
  pengguna diarahkan ke `/login`.
- URL API lewat `--dart-define=CAMPUS_API_URL=...`, tidak di-hardcode.

## Testing

```bash
flutter analyze
flutter test
```

Hasil terakhir: `flutter analyze` bersih, 26 test lulus. Yang diuji:

| File | Cakupan |
| --- | --- |
| `test/notification_route_test.dart` | parsing payload → route (kosong, tanpa slash, tipe salah) |
| `test/session_keeper_test.dart` | refresh sekali, gagal → sesi dibersihkan |
| `test/api_errors_test.dart` | 401/timeout/offline/5xx → pesan ramah |
| `test/auth_notifier_test.dart` | login menyimpan token, logout menghapus |
| `test/app_test.dart` | guard route menahan di `/login`, login membuka beranda |
| `test/push_service_test.dart` | `maskToken` memotong ID, `syncDeviceToBackend` aman tanpa Firebase |

## AI Challenge

Codelab meminta prompt, output awal AI, daftar perbaikan manual, dan tabel uji
disimpan di `docs/`. Isinya:

| Dokumen | Isi |
| --- | --- |
| `docs/ai-challenge/01-prompt.md` | Tiga prompt yang dipakai, apa adanya |
| `docs/ai-challenge/02-draf-awal-ai.md` | Kode draf pertama + kegagalan analyzer-nya |
| `docs/ai-challenge/03-perbaikan-manual.md` | 15 temuan: **5 dari analyzer, 10 dari pembacaan ulang** |
| `docs/uji-tiga-state.md` | Tabel uji yang harus diisi setelah uji perangkat |

Temuan yang paling penting justru yang tidak dilaporkan analyzer: channel
notifikasi tidak dibuat (banner FCM background dibuang Android tanpa error),
token hanya di-print (backend menyimpan nilai basi), dan deep link hilang saat
sesi habis.

## Struktur folder

```
lib/
├── main.dart
├── routes.dart
├── data/          token_store, auth_repository, session_keeper, api_client, api_errors
├── providers/     auth_provider, app_providers (router + push)
├── messaging/     push_service, notification_route
└── pages/         login, home, announcement, debug
docs/              payload contoh + catatan implementasi
screenshots/       bukti uji tiga app state
test/              unit + widget test
```

## Dokumen pendukung

- [`docs/praktikum-3-implementasi.md`](docs/praktikum-3-implementasi.md) —
  pemetaan tiap butir praktikum ke kode, plus catatan jebakan.
- [`docs/android-studio.md`](docs/android-studio.md) — setup Android Studio,
  emulator Play Store, Firebase, dan masalah umum.
- [`docs/fcm-kirim-pesan.md`](docs/fcm-kirim-pesan.md) — cara mengirim pesan uji
  (Console, HTTP v1, atau tombol Debug).
- [`docs/fcm-payload.json`](docs/fcm-payload.json) — payload siap kirim.
- [`docs/uji-tiga-state.md`](docs/uji-tiga-state.md) — tabel uji
  foreground/background/terminated yang harus diisi setelah uji perangkat.
- [`docs/verifikasi-ai.md`](docs/verifikasi-ai.md) — checklist verifikasi draf AI
  beserta bukti kodenya.
- [`docs/ai-challenge/`](docs/ai-challenge/README.md) — prompt, draf awal AI,
  dan daftar perbaikan manual (15 temuan: 5 dari analyzer, 10 dari pembacaan
  ulang).
