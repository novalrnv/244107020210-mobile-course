# Screenshots

Simpan bukti uji di folder ini dengan nama file berikut.

| File | Isi yang harus terlihat |
| --- | --- |
| `debug-token-terpotong.png` | Halaman Debug dengan Firebase Installation ID terpotong (`xxxxxxxxxxxx...`), izin notifikasi, status topik |
| `foreground-banner.png` | Aplikasi terbuka + banner lokal muncul di atasnya |
| `foreground-deeplink.png` | Setelah banner diklik: halaman `/pengumuman/3` |
| `background-banner.png` | Banner sistem muncul saat aplikasi di background |
| `background-deeplink.png` | Setelah banner diklik dari background: halaman `/pengumuman/3` |
| `terminated-banner.png` | Banner sistem saat aplikasi sudah di-swipe-close |
| `terminated-deeplink.png` | Aplikasi terbuka langsung di `/pengumuman/3` |
| `fcm-console-test.png` | Campaign percobaan di Firebase Console |

Aturan: **jangan** pernah menampilkan token atau ID perangkat secara penuh di
screenshot. Nilai penuh cukup dicatat di laporan pribadi, bukan di repository.

## Kebutuhan per screenshot

| Screenshot | Butuh Firebase? | Tanpa `google-services.json` |
| --- | --- | --- |
| `debug-token-terpotong.png` | Ya | Halaman Debug hanya menampilkan "Firebase belum dikonfigurasi" dan ID kosong |
| `foreground-banner.png` | Tidak | Bisa lewat tombol **Kirim notifikasi uji** di halaman Debug |
| `foreground-deeplink.png` | Tidak | Bisa lewat jalur yang sama |
| `background-banner.png` | Ya | Banner sistem hanya muncul untuk `notification payload` FCM asli |
| `background-deeplink.png` | Ya | Ikut jalur background |
| `terminated-banner.png` | Ya | Ikut jalur background |
| `terminated-deeplink.png` | Sebagian | Jalur lokal bisa membuktikan cold start via `getNotificationAppLaunchDetails()` |
| `fcm-console-test.png` | Ya | Campaign hanya ada di Firebase Console |

Jalur lokal (Uji B di [`../docs/uji-tiga-state.md`](../docs/uji-tiga-state.md))
cukup untuk dua screenshot pertama. Enam sisanya menunggu
`android/app/google-services.json`.

