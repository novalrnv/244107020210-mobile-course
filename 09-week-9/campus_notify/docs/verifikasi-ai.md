# AI Verification Checklist

Checklist dari codelab, dijawab dengan menunjuk kode yang berjalan. Dipakai saat
demo: setiap klaim harus bisa ditunjukkan di layar.

| Butir checklist | Status | Bukti |
| --- | --- | --- |
| Background handler berupa fungsi top-level dengan `@pragma('vm:entry-point')` | Lulus | `lib/messaging/push_service.dart` — `firebaseMessagingBackgroundHandler` di luar kelas |
| `onTokenRefresh`/`onRegistered` benar-benar mengirim ke backend, bukan hanya `print` | Lulus (setelah 1 perbaikan) | `_sendTokenToBackend()` → `POST /devices` dengan `fcm_token` + `platform`. Sempat **gagal total**: `register()` melempar `IllegalStateException` karena flag `firebase_messaging_installation_id_enabled` belum ada di manifest. Lihat temuan C1 |
| Foreground memakai local notification manual | Lulus | `_onForegroundMessage()` → `showLocalNotification()` |
| Klik dari tiga state masuk ke rute yang benar | **Perlu bukti manual** | Isi `docs/uji-tiga-state.md` setelah uji perangkat |
| Token/secret tidak di-hardcode dan tidak di-log penuh | Lulus | `maskToken()` (12 karakter), base URL lewat `--dart-define`, token auth di secure storage |
| Tidak ada `BuildContext`/Riverpod di background handler | Lulus | Body handler kosong; navigasi lewat `onMessageOpenedApp` dan `getInitialMessage` |
| ID perangkat terkirim atas nama user yang login | Lulus (setelah 1 perbaikan) | `syncDeviceToBackend()` dipanggil dari `main.dart` saat login berhasil dan saat sesi sudah aktif. Lihat temuan C2 |

Rincian tiap temuan dan alasannya: [`ai-challenge/03-perbaikan-manual.md`](ai-challenge/03-perbaikan-manual.md).

## Temuan yang lolos dari analyzer *dan* pembacaan ulang

Dua hal berikut hanya ketahuan setelah membandingkan kode dengan dokumentasi
SDK native. Keduanya tidak muncul di `flutter analyze`, tidak membuat test gagal,
dan tidak terlihat dari membaca `push_service.dart` sendirian.

| # | Temuan | Akibat bila dibiarkan |
| --- | --- | --- |
| C1 | `register()` butuh `<meta-data android:name="firebase_messaging_installation_id_enabled" android:value="true" />` di `AndroidManifest.xml` | `IllegalStateException`, `onRegistered` tidak emit, token **tidak pernah** sampai ke backend |
| C2 | `attach()` berjalan sebelum login, sehingga kiriman pertama tidak punya konteks user | Backend menyimpan ID tanpa pemilik; setelah login tidak ada kiriman ulang |


## Bukti otomatis

```bash
flutter analyze   # No issues found
flutter test      # 26 test lulus
```

| File test | Cakupan |
| --- | --- |
| `test/notification_route_test.dart` | payload → route: kosong, tanpa slash, tipe salah |
| `test/session_keeper_test.dart` | refresh sekali, gagal → sesi dibersihkan |
| `test/api_errors_test.dart` | 401/timeout/offline/5xx → pesan ramah |
| `test/auth_notifier_test.dart` | login menyimpan token, logout menghapus |
| `test/app_test.dart` | guard route menahan di `/login`, login membuka beranda |
| `test/push_service_test.dart` | `maskToken` memotong ID; `syncDeviceToBackend` aman tanpa Firebase |

Bukti manifest: `flutter build apk --debug` berhasil, dan flag
`firebase_messaging_installation_id_enabled` muncul di
`build/app/intermediates/merged_manifest/debug/.../AndroidManifest.xml`.


## Yang tidak bisa dibuktikan otomatis

Tiga app state dan perilaku banner. Keduanya butuh perangkat dengan Google Play
Services. Emulator tanpa Play Services sering menghasilkan ID null, sehingga
hasilnya tidak mewakili perangkat nyata.
