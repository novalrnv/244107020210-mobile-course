# Panduan Belajar: Empat Tugas Minggu 9

Dokumen ini menjelaskan apa yang dibangun, mengapa dipilih cara itu, dan
konsep apa yang perlu dipahami. Ditulis untuk dibaca ulang sebelum presentasi,
bukan sebagai daftar fitur.

Empat tugas yang diminta:

1. Login lewat API sungguhan.
2. Notifikasi masuk daftar, dan hilang saat dibaca.
3. Notifikasi muncul di icon aplikasi.
4. Notifikasi berbunyi dengan suara kustom.

Semua kode ada di repository ini. Setiap bagian menyebut file yang bisa dibuka
langsung.

---

## Gambaran besar

Aplikasi ini punya dua "dunia" yang harus disambungkan:

```
Laravel (06-week-6/api-mahasiswa)          Flutter (09-week-9/campus_notify)
─────────────────────────────────          ────────────────────────────────
users, personal_access_tokens,             AuthRepository  -> token
devices                                    SecureTokenStore -> simpan token
                                           InboxRepository -> daftar notifikasi
                                           PushService     -> banner + suara
```

Tugas 1 menyambung dunia kiri ke kanan lewat HTTP. Tugas 2 sampai 4 mengurus
apa yang terjadi setelah notifikasi tiba.

---

## Tugas 1: Login lewat API

### Masalahnya

Versi codelab memakai mock auth: email apa pun dengan kata sandi 6 karakter
dianggap sah. Itu cukup untuk belajar guard route, tapi tidak membuktikan
apa pun tentang autentikasi.

### Yang dibangun

Sisi Laravel (`06-week-6/api-mahasiswa`):

| Berkas | Isi |
| --- | --- |
| `app/Http/Controllers/Api/AuthController.php` | `POST /api/login`, `/api/refresh`, `/api/logout`, `GET /api/me` |
| `app/Http/Controllers/Api/DeviceController.php` | `POST /api/devices` |
| `app/Models/Device.php` + migrasi `devices` | tabel perangkat: `fcm_token`, `platform`, `user_id` |
| `app/Http/Middleware/ForceJsonResponse.php` | memaksa `Accept: application/json` |
| `database/seeders/` | user `noval@gmail.com` / `231105`, idempoten (`updateOrCreate`) |

Sisi Flutter:

| Berkas | Isi |
| --- | --- |
| `lib/data/auth_repository.dart` | klien HTTP ke `/login`, `/refresh`, `/logout` |
| `lib/data/token_store.dart` | simpan token di `flutter_secure_storage` |
| `lib/providers/auth_provider.dart` | `AuthNotifier`: login, logout, status sesi |
| `lib/data/api_client.dart` | `ApiConfig.baseUrl`, interceptor 401 |

### Konsep yang dipakai

**Sanctum token, bukan session cookie.** Aplikasi mobile tidak punya cookie
jar. Sanctum menerbitkan token acak yang dikirim di header
`Authorization: Bearer <token>`. Server menyimpan hash token di tabel
`personal_access_tokens`, jadi database tidak pernah menyimpan token aslinya.

**Refresh token diputar.** `/api/refresh` menghapus token lama dan menerbitkan
yang baru. Kalau token lama dicoba lagi, server menjawab `401`. Ini membatasi
kerusakan kalau token bocor: penyerang hanya punya satu jendela waktu.

**Token disimpan di secure storage, bukan SharedPreferences.**
`flutter_secure_storage` menulis lewat Android Keystore. File
`shared_prefs/*.xml` bisa dibaca lewat `adb backup` atau di perangkat root;
penyimpanan Keystore tidak.

**Kenapa `Accept: application/json` wajib.** Laravel mendeteksi permintaan
non-JSON dan mencoba mengalihkan ke halaman login web. Karena proyek ini
API-only, route `login` tidak ada, dan hasilnya `500 Route [login] not defined`.
Memasang `ForceJsonResponse` di middleware membuat server selalu membalas JSON
apa pun header dari klien.

**Kenapa login gagal membalas `422`, bukan `401`.** Klien punya penanganan
khusus untuk `401`: ia menganggap sesi berakhir, lalu menghapus token dan
melempar pengguna ke halaman login. Kalau kredensial salah juga dibalas `401`,
pesan yang muncul adalah "Sesi Anda berakhir", bukan "Email atau kata sandi
salah". `422` memisahkan dua kejadian yang berbeda itu.

**Kenapa `POST /devices` menerima token opsional.** `onRegistered` dari FCM
menyala sebelum pengguna login, jadi belum ada token untuk dikirim. Kalau
endpoint ini mewajibkan login, ID perangkat tidak akan pernah sampai ke
backend. Karena itu `user_id` boleh `NULL`, dan setelah login
`syncDeviceToBackend()` dipanggil ulang untuk mengisi `user_id`. Kuncinya
`fcm_token` dengan `updateOrCreate`, jadi tidak ada baris ganda.

### Cara memeriksanya

```bash
# salah
curl -s -X POST http://127.0.0.1:8000/api/login \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d '{"email":"noval@gmail.com","password":"salah"}'
# -> 422 {"message":"Email atau kata sandi salah."}

# benar
curl -s -X POST http://127.0.0.1:8000/api/login \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d '{"email":"noval@gmail.com","password":"231105"}'
# -> 200 {"token":"...","user":{...}}
```

---

## Tugas 2: Kotak masuk, baca berarti hilang

### Masalahnya

Notifikasi FCM bersifat sementara. Kalau pengguna tidak melihatnya saat muncul,
pesannya hilang. Yang diminta: notifikasi masuk ke sebuah daftar, dan saat
dibaca, item itu hilang dari daftar.

### Yang dibangun

| Berkas | Peran |
| --- | --- |
| `lib/notifications/inbox_item.dart` | model satu notifikasi, plus `toJson`/`fromJson` yang tahan data rusak |
| `lib/notifications/inbox_store.dart` | `InboxStorage` (antarmuka), `PrefsInboxStorage` (nyata), `InboxRepository` (operasi) |
| `lib/notifications/message_mapper.dart` | mengubah isi pesan jadi `InboxItem`, tanpa bergantung pada Firebase |
| `lib/providers/inbox_provider.dart` | `inboxProvider`, `unreadCountProvider` |
| `lib/pages/inbox_page.dart` | halaman `/notifikasi` |
| `lib/messaging/push_service.dart` | menangkap pesan dari empat jalur, menulis ke kotak masuk |

### Empat jalur masuknya pesan

Notifikasi bisa tiba dalam empat situasi, dan semuanya harus menulis ke daftar:

| Jalur | Kapan | Penangan |
| --- | --- | --- |
| `onMessage` | aplikasi sedang terbuka | `_onForegroundMessage` |
| background handler | aplikasi di background atau mati | `firebaseBackgroundHandler` (fungsi top-level) |
| `onMessageOpenedApp` | pengguna mengetuk banner sistem | `_onMessageOpened` |
| `getInitialMessage` | aplikasi dibuka dari banner saat mati | `_onMessageOpened` |

Tiga di antaranya berjalan di isolate berbeda dari UI. Inilah sumber sebagian
besar masalah di tugas ini.

### Tiga keputusan yang perlu bisa dijelaskan

**1. `SharedPreferencesAsync`, bukan `SharedPreferences.getInstance()`.**

`SharedPreferences` biasa menyimpan cache di memori per isolate. Handler
background FCM berjalan di isolate lain. Akibatnya, tulisan dari background
tidak terlihat oleh UI, dan UI bisa menimpa tulisan itu saat menyimpan daftar
berikutnya. `SharedPreferencesAsync` membaca dan menulis langsung ke
penyimpanan, jadi kedua isolate melihat data yang sama.

Buktinya ada di perangkat: berkasnya bernama
`files/datastore/FlutterSharedPreferences.preferences_pb`, bukan
`shared_prefs/FlutterSharedPreferences.xml`. Artinya paket benar-benar memakai
DataStore, bukan XML lama.

**2. ID pesan memakai `messageId` FCM, dengan cadangan hash buatan sendiri.**

`String.hashCode` di Dart tidak dijamin sama antar isolate. Kalau dipakai
sebagai ID, pesan yang sama bisa tercatat dua kali: sekali oleh background
handler, sekali oleh UI. `message_mapper.dart` memakai `messageId` dari FCM,
dan kalau kosong, memakai FNV-1a yang deterministik.

**3. Baca berarti hapus, bukan menandai `read = true`.**

Tugas meminta item hilang dari daftar saat dibaca. Tidak ada kolom `read`,
sehingga tidak mungkin ada item yang "sudah dibaca tapi masih tampil".
Konsekuensinya menyenangkan: jumlah notifikasi belum dibaca selalu sama dengan
panjang daftar, dan `unreadCountProvider` jadi satu baris.

```dart
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(inboxProvider).value?.length ?? 0;
});
```

### Alur saat item diketuk

```
ketuk item
  -> InboxNotifier.markRead(id)      hapus dari penyimpanan
  -> state diperbarui                item hilang dari layar
  -> context.push(item.route)        pindah ke /pengumuman/3
```

Urutannya penting: hapus dulu, baru navigasi. Kalau dibalik, pengguna bisa
kembali ke daftar dan masih melihat item yang sudah dibaca.

### Kenapa banner lokal membawa ID item

Saat pengguna mengetuk banner (bukan item di daftar), aplikasi harus tahu item
mana yang dihapus. Karena itu payload banner lokal menyimpan ID-nya:

```
inbox:<id>|<route>
```

`NotificationPayload.encode` dan `NotificationPayload.decode` di
`lib/messaging/notification_route.dart` mengurus format ini. Saat banner
diketuk, `_onLocalNotificationTapped` membaca ID, menghapus item yang tepat,
lalu navigasi.

### Keadaan yang harus ditangani halaman daftar

| Keadaan | Tampilan |
| --- | --- |
| memuat | `CircularProgressIndicator` |
| kosong | ikon + "Tidak ada notifikasi" + penjelasan bahwa item yang dibaca hilang |
| ada isi | `ListView` dengan waktu terima ("Baru saja", "3 jam lalu", "26 Okt 2026") |
| gagal | teks "Gagal memuat notifikasi" |

Selain mengetuk, item juga bisa digeser ke kiri untuk dibuang. Tombol
"Hapus semua" muncul di AppBar hanya kalau daftar tidak kosong.

---

## Tugas 3: Notifikasi di icon

### Dua tempat berbeda

Ini bagian yang paling sering salah dipahami. Ada dua "icon" yang berbeda:

| Icon | Dikendalikan oleh | Yang muncul |
| --- | --- | --- |
| Lonceng di AppBar | `Badge.count` di dalam aplikasi | angka pasti, misal `1` |
| Icon aplikasi di launcher | sistem, dari `showBadge` pada channel | titik, atau angka kalau launcher mendukung |

`Badge.count` di `lib/pages/home_page.dart`:

```dart
Badge.count(
  count: ref.watch(unreadCountProvider),
  isLabelVisible: ref.watch(unreadCountProvider) > 0,
  child: const Icon(Icons.notifications_outlined),
)
```

Angkanya berasal dari panjang kotak masuk, jadi otomatis turun saat item
dibaca. Ini yang paling bisa diandalkan saat demo.

Untuk launcher, `showBadge: true` dipasang di dua tempat: pada
`AndroidNotificationChannel` dan pada `AndroidNotificationDetails`
(parameter `channelShowBadge`). Perlu diperhatikan: Android hanya memakai
pengaturan channel saat channel **pertama kali** dibuat. Kalau channel sudah
ada di perangkat, perubahan `showBadge` diabaikan. Itu sebabnya pengujian
harus memakai channel baru atau menghapus aplikasi dulu.

Di perangkat uji (realme RMX2103, ColorOS), launcher menampilkan titik, bukan
angka. `dumpsys notification` tetap melaporkan `mShowBadge=true`, jadi
pengaturannya benar; yang tidak mendukung adalah launcher-nya. Ini batasan
sistem, bukan bug aplikasi, dan sebaiknya disebut apa adanya saat presentasi.

---

## Tugas 4: Suara kustom

### Masalahnya

Android tidak mengizinkan suara channel notifikasi diubah setelah channel itu
dibuat. Pengguna bisa mengubahnya sendiri lewat pengaturan; aplikasi tidak.
Channel `pengumuman` sudah pernah dibuat di perangkat uji tanpa suara kustom.
Kalau kode hanya menambahkan `sound:` pada channel yang sama, tidak akan
terjadi apa-apa, dan tidak ada pesan error.

### Solusinya

1. Suara dibuat sebagai berkas sendiri: `android/app/src/main/res/raw/notif.wav`.
   Berkas ini dihasilkan `tool/buat_suara.py` (dua nada bel pendek, 16-bit PCM
   mono 44.1 kHz).
2. Channel baru dengan ID `pengumuman_v2` dibuat lewat
   `_ensureChannel()`, kali ini dengan
   `sound: RawResourceAndroidNotificationSound('notif')`.
3. Channel lama `pengumuman` dihapus, supaya pengaturan notifikasi aplikasi
   tidak menampilkan dua channel dengan nama yang sama.
4. `AndroidManifest.xml` diarahkan ke channel dan suara yang baru, karena
   banner FCM saat aplikasi di background dibuat oleh sistem, bukan oleh
   `flutter_local_notifications`:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="pengumuman_v2" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_sound"
    android:value="notif" />
```

### Kenapa ada tes untuk konfigurasi ini

Nilai channel dan nama suara ada di dua tempat: kode Dart dan manifest. Kalau
keduanya berbeda, Android membuang notifikasi FCM background **tanpa pesan
error apa pun**. Tidak ada exception, tidak ada log. Notifikasi hanya tidak
muncul.

`test/notification_config_test.dart` membaca manifest sebagai berkas dan
membandingkan nilainya dengan konstanta di `PushService`. Tes ini murah dan
menangkap kesalahan yang tidak akan tertangkap `flutter analyze`.

### Cara membuktikannya

```bash
adb shell dumpsys notification --noredact | grep -A2 campus_notify
```

Yang dicari:

```
mSound= android.resource://id.polinema.campus_notify/raw/notif
effectiveNotificationChannel=NotificationChannel{mId='pengumuman_v2', ...}
```

Kalau `mSound` menunjuk ke `raw/notif`, Android benar-benar memakai berkas
bundel itu, bukan suara bawaan sistem.

---

## Yang perlu dijalankan saat demo

### Sekali di awal

```bat
tool\demo.bat
```

Skrip ini menyalakan MySQL, menjalankan Laravel di `127.0.0.1:8000`, dan
memasang `adb reverse tcp:8000 tcp:8000`.

`adb reverse` wajib kalau memakai kabel USB. Tanpa itu, `127.0.0.1` di dalam
HP menunjuk ke HP itu sendiri, bukan ke laptop.

### Urutan demo

| Langkah | Yang ditunjukkan | Tugas |
| --- | --- | --- |
| Login `noval@gmail.com` / `231105` | token asli dari server, bukan mock | 1 |
| Buka halaman Debug | ID perangkat terpotong 12 karakter, status sinkronisasi | 1 |
| Tekan **Kirim notifikasi uji** | banner muncul, lonceng menampilkan `1` | 2, 3, 4 |
| Buka lonceng, ketuk item | item hilang, pindah ke detail pengumuman, angka hilang | 2, 3 |
| Tekan Home, ketuk banner di laci notifikasi | aplikasi kembali ke `/pengumuman/3` | 2 |
| Tutup aplikasi dari Recents, ketuk banner | cold start langsung di `/pengumuman/3` | 2 |

Untuk suara, keluarkan HP dari mode senyap sebelum demo. `dumpsys` membuktikan
channel-nya benar, tetapi telinga hadirin yang membuktikan bunyinya.

---

## Jebakan yang sudah dilewati

Ini bagian yang paling berguna kalau nanti ada masalah serupa.

| Gejala | Penyebab | Perbaikan |
| --- | --- | --- |
| `500 Route [login] not defined` | Laravel mencoba mengalihkan ke halaman login web | `Accept: application/json` di klien, dan middleware `ForceJsonResponse` |
| Pesan "Sesi Anda berakhir" saat salah kata sandi | login gagal membalas `401` | balas `422` untuk kredensial salah |
| Aplikasi berputar di spinner selamanya | `flutter_secure_storage` melempar `TRY_AGAIN` setelah reinstall di ColorOS, `read()` tidak pernah selesai | setiap operasi diberi `.timeout(5s)`, gagal berarti `null` |
| Notifikasi dari background tidak masuk daftar | handler background berjalan di isolate lain | `SharedPreferencesAsync`, dan `DartPluginRegistrant.ensureInitialized()` sebelum menulis |
| Satu pesan tercatat dua kali | `String.hashCode` berbeda antar isolate | pakai `messageId` FCM, cadangan FNV-1a |
| Suara kustom tidak terpakai | channel lama tidak bisa diubah | channel baru `pengumuman_v2`, channel lama dihapus |
| Notifikasi FCM background hilang tanpa error | ID channel di manifest tidak cocok dengan yang dibuat di kode | `notification_config_test.dart` |
| Angka badge tidak muncul di icon launcher | launcher ColorOS hanya menampilkan titik | pakai `Badge.count` di dalam aplikasi untuk demo angka |

---

## Peta berkas

```
lib/
├── data/
│   ├── auth_repository.dart     login, refresh, logout ke API
│   ├── token_store.dart         secure storage + timeout
│   ├── api_client.dart          ApiConfig.baseUrl, interceptor 401
│   └── session_keeper.dart      refresh sekali lalu retry
├── notifications/
│   ├── inbox_item.dart          model satu notifikasi
│   ├── inbox_store.dart         InboxStorage, PrefsInboxStorage, InboxRepository
│   └── message_mapper.dart      pesan -> InboxItem (FNV-1a)
├── providers/
│   ├── auth_provider.dart       AuthNotifier
│   ├── inbox_provider.dart      inboxProvider, unreadCountProvider
│   └── app_providers.dart       router + PushService
├── messaging/
│   ├── push_service.dart        channel, suara, banner, empat jalur pesan
│   └── notification_route.dart  parsing route + NotificationPayload
└── pages/
    ├── login_page.dart
    ├── home_page.dart           lonceng + Badge.count
    ├── inbox_page.dart          /notifikasi
    ├── announcement_page.dart   /pengumuman/:id
    └── debug_page.dart          bukti izin, ID, uji banner

android/app/src/main/
├── AndroidManifest.xml          channel + suara default untuk FCM
└── res/raw/notif.wav            suara kustom

test/                            55 tes
tool/
├── demo.bat                     nyalakan MySQL, Laravel, adb reverse
└── buat_suara.py                pembuat notif.wav
```

---

## Istilah

| Istilah | Arti singkat |
| --- | --- |
| Sanctum | paket Laravel untuk token API, dipakai aplikasi mobile tanpa cookie |
| FCM | Firebase Cloud Messaging, layanan pengantar pesan dari Google |
| FID | Firebase Installation ID, pengenal instalasi aplikasi di satu perangkat |
| Channel notifikasi | "kotak" pengaturan per jenis notifikasi di Android; suara dan badge melekat di sini dan tidak bisa diubah setelah dibuat |
| Isolate | unit eksekusi Dart yang punya memori sendiri; handler background FCM berjalan di isolate terpisah dari UI |
| Deep link | membuka halaman tertentu langsung dari notifikasi, di sini `/pengumuman/:id` |
| Badge | penanda di icon aplikasi yang menunjukkan ada notifikasi belum dibaca |

---

## Referensi

- [Laravel Sanctum](https://laravel.com/docs/sanctum)
- [FCM: message types](https://firebase.google.com/docs/cloud-messaging/concept-options)
- [flutter_local_notifications: notification channels](https://pub.dev/packages/flutter_local_notifications)
- [Android: notification channels](https://developer.android.com/develop/ui/views/notifications/channels)
- [Android: notification badges](https://developer.android.com/develop/ui/views/notifications/badges)
- [shared_preferences: SharedPreferencesAsync](https://pub.dev/packages/shared_preferences)
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- [GoRouter: deep linking](https://go_router.dev/)
