# Tabel Hasil Uji Tiga App State

Isi tabel ini **setelah** menguji di perangkat. Jangan diisi dari perkiraan.
Bukti pendukung (screenshot) masuk ke `screenshots/`.

Perangkat yang dipakai: realme RMX2103 (perangkat fisik)
Versi Android/iOS: Android 11 (API 30)
Tanggal uji: 2 November 2026

## Uji A — Jalur FCM sungguhan

Payload: `docs/fcm-payload.json` (topik `pengumuman-kampus`, `route`
`/pengumuman/3`).

| State | Yang diharapkan | Cara uji | Hasil | Bukti |
| --- | --- | --- | --- | --- |
| Foreground | Banner lokal muncul, klik masuk `/pengumuman/3` | Aplikasi terbuka, kirim dari Firebase Console | Belum diuji ulang di sesi ini. Yang terbukti baru jalur lokal (Uji B), bukan pengiriman dari Console. | `screenshots/foreground-*.png` |
| Background | Banner sistem muncul, klik masuk rute benar | Tekan Home, kirim, klik banner | Belum diuji ulang di sesi ini. Yang terbukti baru jalur lokal (Uji B). | `screenshots/background-*.png` |
| Terminated | Aplikasi terbuka langsung di rute benar | Swipe-close, kirim, klik banner | Belum diuji ulang di sesi ini. Yang terbukti baru jalur lokal (Uji B). | `screenshots/terminated-*.png` |

## Uji B — Jalur lokal (tanpa Firebase)

Dipakai bila `google-services.json` belum tersedia. Membuktikan jalur
`flutter_local_notifications` dan deep link, **bukan** perilaku `notification
payload` FCM.

| Langkah | Yang diharapkan | Hasil |
| --- | --- | --- |
| Debug → **Kirim notifikasi uji** saat aplikasi terbuka | Banner lokal muncul di atas aplikasi | **Lulus.** `dumpsys notification` menampilkan `android.title=Jadwal kuliah berubah`, `channel=pengumuman_v2`, `mSound=android.resource://id.polinema.campus_notify/raw/notif`. Item masuk kotak masuk (`inbox_items` berisi satu entri) dan badge lonceng berubah jadi `1`. |
| Banner muncul → tekan Home → klik banner | Kembali ke aplikasi di `/pengumuman/3` | **Lulus.** Setelah Home, `mResumedActivity` pindah ke launcher. Mengetuk banner mengembalikan `MainActivity` ke depan dan layar berakhir di "Detail pengumuman" dengan label "Dibuka dari deep link /pengumuman/3". |
| Banner muncul → swipe-close aplikasi → klik banner | Cold start langsung di `/pengumuman/3` | **Lulus.** Setelah swipe-close dari Recents, `pidof` kosong (proses benar-benar mati). Mengetuk banner memunculkan PID baru, lalu aplikasi terbuka langsung di "Detail pengumuman" dengan label "Dibuka dari deep link /pengumuman/3". |

Catatan: baris ketiga diuji dengan menghapus aplikasi dari Recents, bukan
tombol Force stop. Force stop membatalkan notifikasi yang tertunda di sistem,
sehingga tidak bisa dipakai untuk menguji jalur ini.

Baris kedua juga membuktikan bahwa item kotak masuk terhapus saat notifikasi
dibuka dari luar aplikasi: setelah dibuka, `inbox_items` kosong dan angka di
lonceng hilang.

## Uji C — Token lifecycle

| Langkah | Yang diharapkan | Hasil |
| --- | --- | --- |
| Buka halaman Debug | ID perangkat tampil terpotong 12 karakter | **Lulus.** Baris "Firebase Installation ID" menampilkan `f4Zid_36TWC-...`. |
| Hapus data aplikasi / reinstall, buka lagi | `onRegistered` mengirim ID baru; ID di backend berubah | **Lulus.** Setelah reinstall, ID baru masuk ke `devices` sebagai baris ke-5 dengan ID berbeda dari baris ke-4. |
| Login → lihat **Sinkronisasi terakhir** | Tertulis "Token terkirim ke POST /devices" (kiriman ulang atas nama user) | **Lulus.** Login `noval@gmail.com` membuat baris `personal_access_tokens` baru, lalu `POST /api/devices` terpanggil dan `user_id` pada baris perangkat berubah dari `NULL` menjadi `1`. |
| Matikan internet, tekan **Registrasi FCM** | Pesan ramah, bukan crash | Belum diuji. |
| Tolak izin notifikasi | Status "Belum", banner tidak muncul | ⚠️ tidak dapat diuji di Android 11, lihat catatan di bawah |
| Login → hapus token di backend → buka pengumuman | 401 → refresh → retry berhasil tanpa login ulang | **Lulus di level API** (curl): token lama setelah `/api/refresh` dipakai → `401`, token baru → `200`. Perilaku retry di aplikasi ditutup unit test `session_keeper_test.dart`. |

## Uji D — Topic

| Langkah | Yang diharapkan | Hasil |
| --- | --- | --- |
| Debug → **Langganan** | Status topik "Berlangganan" | **Lulus.** Baris "Topik pengumuman-kampus" menampilkan "Berlangganan" setelah login. |
| Kirim ke topik `pengumuman-kampus` | Diterima | Belum diuji ulang di sesi ini. |
| Debug → **Berhenti topik** | Status "Tidak" | Belum diuji. |
| Kirim ke topik lagi | Tidak diterima | Belum diuji. |

## Catatan perangkat uji

Perangkat: **realme RMX2103, Android 11 (API 30)**, Google Play Services dan
Play Store terpasang.

`POST_NOTIFICATIONS` baru menjadi izin runtime sejak **Android 13 (API 33)**.
Di Android 11 notifikasi otomatis diizinkan saat instalasi, sehingga baris
**"Tolak izin notifikasi"** pada Uji C tidak dapat diuji di perangkat ini.
Aplikasi memakai `targetSdk = 36`, jadi di perangkat Android 13+ baris tersebut
relevan dan perlu diuji terpisah.

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
