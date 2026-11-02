# Refleksi

Jawaban atas empat pertanyaan refleksi codelab Minggu 6. Setiap jawaban
menunjuk kode yang benar-benar ada di repository ini, bukan teori umum.

---

## 1. Mengapa refresh token tidak boleh disimpan di SharedPreferences?

`SharedPreferences` di Android menyimpan datanya sebagai file **XML polos** di
`/data/data/<package>/shared_prefs/`. Tidak ada enkripsi, tidak ada kunci yang
dipin ke hardware. Artinya isinya bisa dibaca siapa pun yang bisa menjangkau
direktori itu:

- `adb backup` pada perangkat dengan `allowBackup=true` (default Flutter).
- Perangkat yang sudah di-root.
- Aplikasi backup/file manager pihak ketiga yang punya akses storage.

Bandingkan dengan yang dipakai proyek ini, `lib/data/token_store.dart`:

```dart
class SecureTokenStore implements TokenStore {
  const SecureTokenStore();

  static const _storage = FlutterSecureStorage();
  ...
}
```

`flutter_secure_storage` menulis lewat **Android Keystore** (dan Keychain di
iOS). Kuncinya dipegang sistem operasi dan, di perangkat modern, ditanam di
secure element. Aplikasi lain tidak bisa membacanya meski filesystem-nya
tersalin.

**Risiko konkret bila refresh token bocor.** Refresh token adalah tiket
berumur panjang — di codelab ini 7 hari, di banyak sistem produksi 30–90 hari.
Penyerang yang memegangnya bisa terus menukar access token baru **tanpa pernah
tahu password pengguna**. Yang lebih berbahaya: tidak ada jejak login baru,
jadi pengguna tidak menyadari apa pun. Sesi bisa diperpanjang berbulan-bulan
selama token masih bisa dirotasi.

Access token bocor jauh lebih ringan: umurnya pendek (15 menit di codelab),
jadi jendela penyalahgunaannya sempit.

---

## 2. Apa yang rusak bila `onTokenRefresh` diabaikan selama satu semester?

Ada dua lapis kerusakan, dan lapis kedua yang lebih berbahaya.

**Lapis pertama — yang biasanya diceritakan.** ID perangkat berotasi ketika
pengguna reinstall aplikasi, clear data, atau Firebase melakukan rotasi
keamanan. Backend tetap menyimpan ID lama. Push dikirim ke target yang sudah
tidak ada, FCM membalas sukses di sisi pengirim, dan pengguna tidak menerima
apa pun. Tidak ada error di mana pun — hanya notifikasi yang diam-diam berhenti
datang. Setelah satu semester, daftar perangkat di backend penuh ID mati, dan
tidak ada cara mengetahui mana yang masih hidup tanpa mencoba mengirim.

**Lapis kedua — yang terjadi di proyek ini.** Saat audit, ditemukan bahwa
`FirebaseMessaging.register()` pada `firebase_messaging` 17 melempar
`IllegalStateException` bila flag berikut tidak ada di manifest:

```xml
<meta-data
    android:name="firebase_messaging_installation_id_enabled"
    android:value="true" />
```

Tanpa flag itu, rantainya putus di langkah pertama:

```
register() -> IllegalStateException
           -> onRegistered tidak pernah emit
           -> _sendTokenToBackend() tidak pernah dipanggil
           -> POST /devices tidak pernah terjadi
```

Jadi bukan "ID basi" — melainkan **tidak ada satu pun ID** yang pernah sampai
ke backend, sejak hari pertama. Yang membuat ini mahal: aplikasi tetap berjalan
normal, izin notifikasi bisa diberikan, topik bisa di-subscribe, dan halaman
Debug tidak crash. Satu-satunya gejala adalah kolom ID yang tetap kosong.

Pelajaran yang saya ambil: "mengabaikan `onTokenRefresh`" tidak selalu
menghasilkan bug yang kelihatan. Kadang hasilnya adalah fitur yang tidak pernah
hidup, dan tidak ada yang tahu selama satu semester.

---

## 3. Kapan memakai topik dan kapan memakai token perangkat?

Aturannya sederhana: **kalau isi pesan berbeda per orang, jangan pakai topik.**

**Topik — untuk broadcast.** Penerima tidak perlu diketahui saat mengirim, dan
isinya sama untuk semua. Cocok untuk:

- `pengumuman-kampus`: "Jadwal kuliah berubah", "Kampus libur 17 Agustus".
- `kelas-ti-3a`: "Kelas pengganti Mobile di Ruang A2 jam 13.00".
- `ukm-robotika`: "Latihan rutin dipindah ke hari Sabtu".

Keunggulannya: satu panggilan API menjangkau ribuan perangkat, dan aplikasi
tidak perlu mengirim ID apa pun ke backend. Biayanya: tidak ada personalisasi
dan tidak ada bukti pengiriman per orang.

**Token perangkat (atau FID) — untuk pesan personal.** Isinya spesifik untuk
satu orang dan tidak boleh terbaca orang lain:

- "Nilai Kuis 2 Anda: 85."
- "Tagihan UKT semester ganjil jatuh tempo 10 November."
- "Jadwal bimbingan Anda dengan Bu Rina diubah ke Kamis 09.00."

Kalau ini dikirim lewat topik, seluruh angkatan akan menerima nilai dan tagihan
orang lain. Itu kebocoran data, bukan sekadar notifikasi salah alamat.

Di proyek ini, `PushService.subscribeToTopic()` menangani broadcast, sedangkan
`_sendTokenToBackend()` mengirim ID perangkat ke `POST /devices` supaya backend
punya target untuk pesan personal.

---

## 4. Bagian mana dari draf AI yang Anda tolak atau perbaiki, dan mengapa?

Rinciannya ada di [`ai-challenge/03-perbaikan-manual.md`](ai-challenge/03-perbaikan-manual.md).
Dari **15 temuan**, hanya **5 yang dilaporkan analyzer**. Sepuluh sisanya baru
muncul saat kode dibaca ulang terhadap checklist dan diuji.

**Yang saya tolak karena desainnya salah:**

| Draf AI | Alasan |
| --- | --- |
| `initFcmToken(onToken: ...)` menyerahkan pengiriman ke pemanggil | Tidak ada jaminan token benar-benar dikirim. Di praktiknya berakhir `print(token)`. Pengiriman harus ada di dalam service. |
| `String? pendingDeepLink` global | Hanya dibaca sekali, tidak pernah di-reset, tidak bisa menampung lebih dari satu klik. Diganti `DeepLinkBuffer` dengan `put()`/`take()`. |
| `message.data['route'] ?? '/'` | Meloloskan nilai non-string ke router. Diganti fungsi murni `routeFromMessage()` yang memvalidasi tipe. |
| `_local.show(message.hashCode, ...)` | Hash bisa bertabrakan antar pesan; banner baru menimpa banner lama. Diganti timestamp. |
| `handleTerminated()` dipanggil sebelum `runApp` | Router belum ada, `go()` tidak berefek. Notifikasi terminated membuka aplikasi di beranda. |

**Yang saya perbaiki karena API berubah:**

- `getToken()` dan `onTokenRefresh` sudah deprecated di `firebase_messaging` 17,
  diganti `register()` + `onRegistered` (berbasis Firebase Installation ID).
- `flutter_local_notifications` 22 mengubah semua argumen `show()` dan
  `initialize()` menjadi named parameter.

**Yang hanya ketahuan dari audit dokumen SDK, bukan dari membaca kode Dart:**

- **C1** — flag `firebase_messaging_installation_id_enabled` wajib ada di
  manifest. README paket Flutter tidak menyebutnya sama sekali.
- **C2** — registrasi perangkat berjalan di `attach()`, yaitu sebelum login,
  sehingga `POST /devices` menerima ID tanpa konteks user. Diperbaiki dengan
  `syncDeviceToBackend()` yang dipanggil ulang setiap login berhasil.

Kesimpulan saya: AI berguna untuk menghasilkan kerangka yang cepat, tetapi
**tidak bisa dijadikan penentu akhir**. Tiga bug termahal di proyek ini
(channel notifikasi tidak dibuat, token tidak pernah terkirim, deep link hilang
saat sesi habis) semuanya lolos `flutter analyze` dengan nilai bersih.
