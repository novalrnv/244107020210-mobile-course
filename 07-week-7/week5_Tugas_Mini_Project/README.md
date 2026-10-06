# Offline Notes - Mini Project

## Tujuan
Aplikasi catatan (notes) sederhana yang berjalan secara offline-first menggunakan Flutter. Aplikasi ini menyimpan data secara lokal menggunakan SQLite dan mendukung sinkronisasi catatan dengan simulasi server remote.

## Fitur Utama
- ✅ **CRUD Catatan** - Tambah, baca, edit, dan hapus catatan
- ✅ **Offline-first** - Data selalu tersimpan lokal, sync dilakukan manual
- ✅ **Dirty Flag** - Badge penanda catatan yang belum di-sync
- ✅ **Toggle Tema** - Beralih antara mode gelap dan terang
- ✅ **Waktu Terakhir Dibuka** - Menampilkan kapan terakhir membuka aplikasi
- ✅ **Sync Catatan** - Simulasi sinkronisasi ke server remote
- ✅ **Urutan Terbaru** - Catatan diurutkan berdasarkan waktu update terbaru

## Stack Teknologi
| Teknologi | Kegunaan |
|---|---|
| Flutter | Framework UI |
| Dart | Bahasa pemrograman |
| sqflite | Database SQLite lokal |
| SharedPreferences | Penyimpanan preferensi (tema, waktu) |
| flutter_riverpod | State management |
| intl | Format tanggal |

## Cara Menjalankan

1. Pastikan Flutter SDK sudah terinstall
2. Clone repository ini
3. Masuk ke folder project:
   ```bash
   cd 05-week-5-local-storage-offline-first
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Jalankan aplikasi:
   ```bash
   flutter run
   ```
6. Jalankan test:
   ```bash
   flutter test
   ```

## Struktur Project
```
lib/
├── main.dart                  # Entry point aplikasi
├── models/
│   └── note.dart              # Model data catatan
├── database/
│   └── database_helper.dart   # Helper SQLite database
├── repositories/
│   └── note_repository.dart   # Repository pattern (lokal + fake remote)
├── providers/
│   ├── note_provider.dart     # Provider Riverpod untuk catatan
│   └── theme_provider.dart    # Provider untuk tema & waktu terakhir
└── screens/
    ├── home_screen.dart       # Halaman utama daftar catatan
    └── note_form_screen.dart  # Halaman tambah/edit catatan
test/
├── note_model_test.dart       # Unit test model Note
└── note_provider_test.dart    # Test provider dengan repository palsu
docs/
├── bukti_mode_pesawat.md      # Dokumentasi bukti mode pesawat & offline-first
├── testing.md                 # Dokumentasi automated testing (9 test passed)
├── ai_challenge.md            # Dokumentasi AI challenge & perbandingan storage
└── img/                       # Gambar screenshot aplikasi
screenshots/                   # Salinan screenshot bukti mode pesawat
README.md                      # File ini
```

## Hasil yang Dicapai
- Aplikasi berjalan dengan baik secara offline
- CRUD catatan berfungsi dengan database SQLite
- Preferensi tema tersimpan menggunakan SharedPreferences
- Dirty flag berfungsi menandai catatan yang belum di-sync
- Sync berhasil mengirim catatan dirty ke simulasi server
- 2 test berhasil lulus (model test + provider test)

## Aturan Konflik yang Dipilih
**Last Write Wins (LWW)**: Ketika ada konflik antara data lokal dan remote, versi dengan `updated_at` yang lebih baru akan menang. Strategi ini dipilih karena:
- Sederhana dan mudah diimplementasikan
- Cocok untuk aplikasi catatan personal (single user)
- Tidak memerlukan UI resolusi konflik yang rumit

## Temuan Verifikasi AI
- AI membantu mempercepat pembuatan boilerplate code
- Struktur arsitektur (repository pattern + Riverpod) disarankan oleh AI
- AI menjelaskan perbandingan antara opsi storage (SharedPreferences vs SQLite vs Hive)
- Kode yang dihasilkan perlu di-review dan disesuaikan dengan kebutuhan spesifik
- AI memberikan contoh implementasi offline-first pattern yang bisa langsung digunakan
