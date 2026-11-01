# Mengirim Pesan Uji

Tiga cara, dari yang paling cepat ke yang paling mirip produksi.

## 1. Firebase Console (paling cepat)

1. Firebase Console → **Messaging** → **Create your first campaign** /
   **New campaign** → **Firebase Notification messages**.
2. Isi `title` = "Jadwal kuliah berubah", `body` = "Kelas Mobile pindah ke
   Ruang A2 jam 13.00".
3. **Additional options → Custom data**:

   | Key | Value |
   | --- | --- |
   | `route` | `/pengumuman/3` |
   | `id` | `3` |

4. Target: aplikasi Android Anda (atau topik `pengumuman-kampus`).
5. **Send**. Uji berurutan untuk tiga state:

   - aplikasi terbuka → banner lokal,
   - tekan Home lalu kirim → banner sistem,
   - swipe-close lalu kirim → banner sistem, klik membuka aplikasi.

## 2. FCM HTTP v1 dengan curl

Butuh service account JSON (Project settings → Service accounts → Generate new
private key). **Jangan commit file itu ke repository.**

```bash
# 1. Ambil access token dari service account
gcloud auth activate-service-account --key-file=service-account.json
ACCESS_TOKEN=$(gcloud auth print-access-token)
PROJECT_ID=id-polinema-campus

# 2. Kirim ke topik
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://fcm.googleapis.com/v1/projects/$PROJECT_ID/messages:send" \
  -d @docs/fcm-payload.json
```

Untuk pesan personal, ganti blok `topic` dengan token perangkat:

```json
{
  "message": {
    "token": "<ID perangkat dari halaman Debug>",
    "notification": { "title": "...", "body": "..." },
    "data": { "route": "/pengumuman/3", "id": "3" }
  }
}
```

## 3. Tanpa Firebase: tombol di halaman Debug

Berguna saat `google-services.json` belum tersedia atau saat demo di laptop.

- **Kirim notifikasi uji** menampilkan banner lokal dengan payload
  `route=/pengumuman/3`, memakai jalur yang sama dengan handler FCM.
- Tekan Home setelah banner muncul, lalu klik banner → aplikasi kembali ke
  `/pengumuman/3`.
- Swipe-close aplikasi, kirim ulang, klik banner → dibuka lewat
  `getNotificationAppLaunchDetails()`.

Yang **tidak** bisa dibuktikan lewat jalur ini: perilaku banner sistem untuk
`notification payload` asli dari FCM. Untuk itu tetap perlu Firebase.

## Cara membaca hasil

Catat di tabel README:

- nama perangkat/emulator dan versi Android,
- apakah banner muncul (dan di state mana),
- rute yang terbuka setelah klik,
- potongan log (`flutter logs`) bila ada yang gagal.

Contoh baris hasil yang baik:

> Pixel 6a, Android 15 — background: banner sistem muncul 2 detik setelah kirim,
> klik membuka `/pengumuman/3`. Terminated: aplikasi cold start 1,8 detik,
> langsung di `/pengumuman/3`.
