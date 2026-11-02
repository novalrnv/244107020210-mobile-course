# Prompt yang Dipakai

Disimpan apa adanya supaya bisa dibandingkan dengan output awal dan perbaikan
manual. Ini yang diminta codelab pada bagian *AI Prompt Challenge*.

## Prompt 1 — PushService

```
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.
Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')
Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.
```

## Prompt 2 — Auth, secure storage, refresh (prasyarat)

Dipakai sebelum PushService, karena notifikasi butuh sesi dan token perangkat
butuh endpoint yang terautentikasi.

```
Lanjutkan project yang sama. Tambahkan:
- TokenStore di atas flutter_secure_storage (access + refresh, tanpa
  SharedPreferences)
- AuthRepository mock yang bentuk API-nya siap diganti Firebase Auth
- Interceptor Dio: tempel Bearer, saat 401 tukar refresh lalu retry SEKALI,
  kalau refresh mati hapus token
- AuthNotifier (Riverpod AsyncNotifier) + guard route GoRouter
- Fungsi murni routeFromMessage(Map) supaya bisa diuji tanpa Firebase
Jangan hardcode URL atau secret. Token tidak boleh di-print penuh.
```

## Prompt 3 — Refactor setelah temuan analyzer

```
flutter analyze gagal. Perbaiki tanpa mengubah perilaku:
- flutter_local_notifications 22 memakai named parameter untuk show() dan
  initialize()
- firebase_messaging 17 menandai getToken/onTokenRefresh deprecated
- DioExceptionType punya case baru transformTimeout
- lint prefer_initializing_formals dan unused_import
Jelaskan setiap perubahan dalam satu baris.
```

## Mengapa prompt-nya dipecah

Satu prompt raksasa menghasilkan service yang mengompilasi tetapi salah
perilaku: channel notifikasi tidak dibuat, token hanya di-print, dan deep link
hilang saat sesi habis. Dipecah tiga, tiap tahap punya kriteria lulus sendiri
(`flutter analyze` bersih → `flutter test` lulus → uji perangkat).
