# Tabel Hasil Uji Tiga App State

Isi tabel ini **setelah** menguji di perangkat. Jangan diisi dari perkiraan.
Bukti pendukung (screenshot) masuk ke `screenshots/`.

Perangkat yang dipakai: ______________________
Versi Android/iOS: ______________________
Tanggal uji: ______________________

## Uji A — Jalur FCM sungguhan

Payload: `docs/fcm-payload.json` (topik `pengumuman-kampus`, `route`
`/pengumuman/3`).

| State | Yang diharapkan | Cara uji | Hasil | Bukti |
| --- | --- | --- | --- | --- |
| Foreground | Banner lokal muncul, klik masuk `/pengumuman/3` | Aplikasi terbuka, kirim dari Firebase Console | | `screenshots/foreground-*.png` |
| Background | Banner sistem muncul, klik masuk rute benar | Tekan Home, kirim, klik banner | | `screenshots/background-*.png` |
| Terminated | Aplikasi terbuka langsung di rute benar | Swipe-close, kirim, klik banner | | `screenshots/terminated-*.png` |

## Uji B — Jalur lokal (tanpa Firebase)

Dipakai bila `google-services.json` belum tersedia. Membuktikan jalur
`flutter_local_notifications` dan deep link, **bukan** perilaku `notification
payload` FCM.

| Langkah | Yang diharapkan | Hasil |
| --- | --- | --- |
| Debug → **Kirim notifikasi uji** saat aplikasi terbuka | Banner lokal muncul di atas aplikasi | |
| Banner muncul → tekan Home → klik banner | Kembali ke aplikasi di `/pengumuman/3` | |
| Banner muncul → swipe-close aplikasi → klik banner | Cold start langsung di `/pengumuman/3` | |

## Uji C — Token lifecycle

| Langkah | Yang diharapkan | Hasil |
| --- | --- | --- |
| Buka halaman Debug | ID perangkat tampil terpotong 12 karakter | |
| Hapus data aplikasi / reinstall, buka lagi | `onRegistered` mengirim ID baru; ID di backend berubah | |
| Matikan internet, tekan **Registrasi FCM** | Pesan ramah, bukan crash | |
| Tolak izin notifikasi | Status "Belum", banner tidak muncul | |
| Login → hapus token di backend → buka pengumuman | 401 → refresh → retry berhasil tanpa login ulang | |

## Uji D — Topic

| Langkah | Yang diharapkan | Hasil |
| --- | --- | --- |
| Debug → **Langganan** | Status topik "Berlangganan" | |
| Kirim ke topik `pengumuman-kampus` | Diterima | |
| Debug → **Berhenti topik** | Status "Tidak" | |
| Kirim ke topik lagi | Tidak diterima | |

## Cara mengisi kolom Hasil

Tulis keadaan nyata, termasuk yang gagal. Contoh yang baik:

> **Background** — banner sistem muncul 2 detik setelah kirim, klik membuka
> `/pengumuman/3`. Sempat gagal sekali: banner tidak muncul karena channel
> `pengumuman` belum dibuat; setelah `_ensureChannel()` ditambahkan, muncul.

Contoh yang tidak berguna: "berhasil". Tanpa detail, tabel ini tidak bisa
dipertahankan saat demo.

## Temuan yang harus dilaporkan bila terjadi

| Gejala | Penyebab umum | Solusi |
| --- | --- | --- |
| ID null di emulator | Emulator tanpa Google Play Services | Pakai emulator ber-Play Store atau perangkat fisik |
| Banner tidak muncul saat foreground | Mengandalkan banner otomatis | Sudah ditangani `_onForegroundMessage` |
| Klik tidak navigasi saat terminated | `getInitialMessage` dipanggil sebelum router | Sudah ditangani urutan di `main.dart` |
| Banner FCM background tidak muncul | Channel belum ada | Sudah ditangani `_ensureChannel` |
| 401 berulang | Retry tanpa penanda | Sudah ditangani `_retriedKey` di `api_client.dart` |
| `MissingPluginException` | Hot reload setelah tambah plugin | Stop penuh, `flutter run` ulang |
| iOS: notifikasi tidak muncul | Belum ada APNs key + capability Push | Konfigurasi di Firebase Console + Xcode |
