# AI Verification Checklist

Checklist dari codelab, dijawab dengan menunjuk kode yang berjalan. Dipakai saat
demo: setiap klaim harus bisa ditunjukkan di layar.

| Butir checklist | Status | Bukti |
| --- | --- | --- |
| Background handler berupa fungsi top-level dengan `@pragma('vm:entry-point')` | Lulus | `lib/messaging/push_service.dart` — `firebaseMessagingBackgroundHandler` di luar kelas |
| `onTokenRefresh`/`onRegistered` benar-benar mengirim ke backend, bukan hanya `print` | Lulus | `_sendTokenToBackend()` → `POST /devices` dengan `fcm_token` + `platform` |
| Foreground memakai local notification manual | Lulus | `_onForegroundMessage()` → `showLocalNotification()` |
| Klik dari tiga state masuk ke rute yang benar | **Perlu bukti manual** | Isi `docs/uji-tiga-state.md` setelah uji perangkat |
| Token/secret tidak di-hardcode dan tidak di-log penuh | Lulus | `maskToken()` (12 karakter), base URL lewat `--dart-define`, token auth di secure storage |
| Tidak ada `BuildContext`/Riverpod di background handler | Lulus | Body handler kosong; navigasi lewat `onMessageOpenedApp` dan `getInitialMessage` |

Rincian tiap temuan dan alasannya: [`ai-challenge/03-perbaikan-manual.md`](ai-challenge/03-perbaikan-manual.md).

## Bukti otomatis

```bash
flutter analyze   # No issues found
flutter test      # 22 test lulus
```

| File test | Cakupan |
| --- | --- |
| `test/notification_route_test.dart` | payload → route: kosong, tanpa slash, tipe salah |
| `test/session_keeper_test.dart` | refresh sekali, gagal → sesi dibersihkan |
| `test/api_errors_test.dart` | 401/timeout/offline/5xx → pesan ramah |
| `test/auth_notifier_test.dart` | login menyimpan token, logout menghapus |
| `test/app_test.dart` | guard route menahan di `/login`, login membuka beranda |

## Yang tidak bisa dibuktikan otomatis

Tiga app state dan perilaku banner. Keduanya butuh perangkat dengan Google Play
Services. Emulator tanpa Play Services sering menghasilkan ID null, sehingga
hasilnya tidak mewakili perangkat nyata.
