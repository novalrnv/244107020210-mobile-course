# Menjalankan di Android Studio

Panduan dari nol sampai aplikasi berjalan di emulator/perangkat dari dalam
Android Studio.

## 1. Prasyarat di komputer

| Kebutuhan | Versi | Cara cek |
| --- | --- | --- |
| Flutter SDK | 3.47+ (Dart 3.13+) | `flutter --version` |
| Android Studio | versi stabil terbaru | Help → About |
| Android SDK Platform | 36 | SDK Manager |
| Gradle JDK | 17 (bundled JBR) | Settings → Build Tools → Gradle |
| Plugin Flutter + Dart di Android Studio | terbaru | Settings → Plugins |

Di mesin ini `flutter doctor` menunjukkan dua hal yang perlu dibereskan:

```
[!] Android toolchain - develop for Android devices (Android SDK version 36.0.0)
    ! Some Android licenses not accepted.
[√] Connected device (2 available)   ← hanya Chrome dan Edge
```

Terima lisensi:

```bash
flutter doctor --android-licenses
```

Lalu buka Android Studio → **Settings → Languages & Frameworks → Android SDK →
SDK Tools**, pastikan terpasang: *Android SDK Build-Tools*, *Android SDK
Platform-Tools*, *Android Emulator*.

## 2. Emulator wajib punya Google Play Store

Ini bukan preferensi gaya. Tanpa Google Play Services, `register()` tidak
pernah menghasilkan Installation ID, sehingga halaman Debug menampilkan "Belum
ada" dan FCM tidak bisa diuji sama sekali.

Di **Device Manager** → **Create Virtual Device** → pilih device (mis. Pixel 7)
→ pada daftar system image, pilih yang **berikon Play Store** (bukan
"Google APIs" saja) → Finish.

Saat ini belum ada emulator terdaftar di mesin ini (`flutter emulators` kosong),
jadi langkah ini perlu dilakukan sekali.

## 3. Buka project

Buka **folder `campus_notify`** (bukan folder `09-week-9`), lalu tunggu:

1. Android Studio menawarkan **Trust Project** → percaya.
2. Gradle sync berjalan otomatis. Bila tidak: **File → Sync Project with
   Gradle Files**.
3. `flutter pub get` dijalankan otomatis; kalau tidak, buka Terminal di
   Android Studio dan jalankan.

`android/local.properties` (berisi `sdk.dir` dan `flutter.sdk`) dibuat otomatis
oleh Flutter. File ini tidak boleh di-commit.

## 4. Firebase (opsional, hanya bila ingin FCM sungguhan)

1. Firebase Console → **Add project** → tambahkan aplikasi **Android**.
2. **Android package name harus** `id.polinema.campus_notify`
   (dari `android/app/build.gradle.kts`, blok `applicationId`).
3. Unduh `google-services.json`, letakkan di **`android/app/`**.
4. **File → Sync Project with Gradle Files**.

Plugin `com.google.gms.google-services` dipasang **bersyarat**: hanya aktif bila
file di atas ada. Jadi project tetap bisa dijalankan sebelum Firebase
dikonfigurasi — halaman Debug akan menampilkan "Firebase belum dikonfigurasi"
dan tombol **Kirim notifikasi uji** tetap bekerja untuk membuktikan banner dan
deep link.

Tanpa langkah ini, semua fitur lain (login, guard route, secure storage, token
refresh, deep link lokal) tetap bisa diuji.

## 5. Pilih konfigurasi run

Dua konfigurasi sudah disiapkan di `.idea/runConfigurations/`:

| Nama | Isi |
| --- | --- |
| `campus_notify (debug)` | `lib/main.dart` tanpa argumen tambahan |
| `campus_notify (API lokal)` | menambah `--dart-define=CAMPUS_API_URL=http://10.0.2.2:8000/api` |

Pilih di dropdown kiri atas, pilih device (emulator Play Store atau iPhone/HP
Android), lalu klik **Run** (Shift+F10) atau **Debug** (Shift+F9).

Untuk backend lain, duplikasi konfigurasi dan ganti nilainya:

```
--dart-define=CAMPUS_API_URL=https://api.kampus.ac.id/api
```

`10.0.2.2` adalah alias `localhost` komputer host dari dalam emulator Android.
Build debug sudah mengizinkan HTTP biasa (`usesCleartextTraffic` di
`android/app/src/debug/AndroidManifest.xml`), build release tidak.

## Yang sudah disiapkan di project ini

| File | Fungsi |
| --- | --- |
| `android/settings.gradle.kts` | Mendaftarkan plugin `com.google.gms.google-services` 4.5.0 |
| `android/app/build.gradle.kts` | Memasang plugin itu hanya bila `google-services.json` ada; desugaring untuk `flutter_local_notifications` |
| `android/app/src/main/AndroidManifest.xml` | Izin `POST_NOTIFICATIONS`, channel default `pengumuman`, ikon notifikasi |
| `android/app/src/debug/AndroidManifest.xml` | `usesCleartextTraffic` untuk API lokal |
| `.idea/runConfigurations/*.xml` | Dua konfigurasi run siap pakai |
| `.gitignore` | Mengabaikan `google-services.json`, `*.jks`, `key.properties`, tetapi **mengizinkan** `runConfigurations` |

`minSdk` 24, `compileSdk` 36, `targetSdk` 36 — semua di atas minimum Firebase
Messaging dan `flutter_local_notifications`.

## Masalah umum di Android Studio

| Gejala | Penyebab | Solusi |
| --- | --- | --- |
| `SDK location not found` | `local.properties` belum ada | Buka project lewat Android Studio, atau jalankan `flutter pub get` |
| `Unsupported class file major version` | Gradle JDK tidak cocok | Settings → Build Tools → Gradle → **Gradle JDK = 17** |
| Tombol Run tidak muncul | Plugin Flutter/Dart belum aktif | Settings → Plugins → pasang, restart IDE |
| `No devices found` | Belum ada AVD / HP belum terdeteksi | Buat AVD ber-Play Store, atau aktifkan USB debugging |
| Build gagal: `google-services.json not found` | File belum ada tetapi plugin dipaksa | Tidak terjadi di project ini (plugin bersyarat). Pastikan file ada di `android/app/`, bukan `android/` |
| Aplikasi jalan, FCM mati | `google-services.json` belum ada | Normal. Tambahkan file lalu sync |
| `MissingPluginException` setelah tambah paket | Hot reload tidak mendaftarkan plugin native | **Stop** lalu Run ulang (bukan hot reload) |
| Banner tidak muncul saat aplikasi terbuka | Izin notifikasi ditolak | Halaman Debug → **Minta izin** |
| Banner FCM background tidak muncul | Channel `pengumuman` belum dibuat | Sudah ditangani `_ensureChannel()`; pastikan versi aplikasi terbaru |
| Build pertama sangat lambat (10-20 menit) | Gradle mengunduh dependency | Normal, build berikutnya jauh lebih cepat |

## Checklist sebelum demo

- [ ] `flutter doctor` bersih untuk kategori Android
- [ ] Emulator ber-Play Store terpasang dan menyala
- [ ] Gradle sync sukses tanpa error
- [ ] `google-services.json` ada di `android/app/` (bila demo FCM)
- [ ] Run configuration dipilih, device dipilih
- [ ] Login berhasil → beranda tampil
- [ ] Halaman Debug: izin notifikasi, Installation ID terpotong, status topik
- [ ] Tombol **Kirim notifikasi uji** → banner muncul → klik → `/pengumuman/3`
