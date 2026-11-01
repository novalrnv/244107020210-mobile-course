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
