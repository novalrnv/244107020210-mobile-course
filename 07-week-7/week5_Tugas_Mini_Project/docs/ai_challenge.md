# AI Challenge - Dokumentasi

## Prompt yang Digunakan

Prompt utama yang digunakan untuk membantu pengerjaan mini project ini:

> "Baca gambar tugas_mini, lalu bantu kerjakan dengan kode program yang tidak terlalu expert"

Prompt tambahan yang digunakan selama pengerjaan:
- Membuat struktur project Flutter dengan arsitektur sederhana
- Implementasi CRUD menggunakan SQLite dan Riverpod
- Implementasi offline-first pattern dengan dirty flag

## Tabel Perbandingan Storage

| Kriteria | SharedPreferences | SQLite (sqflite) | Hive | ObjectBox |
|---|---|---|---|---|
| Tipe Data | Key-value sederhana | Relasional (tabel) | Key-value / Object | Object-oriented |
| Kapasitas | Kecil (setting) | Besar (ribuan data) | Sedang-Besar | Besar |
| Query | Tidak bisa | SQL lengkap | Terbatas | Query builder |
| Kecepatan | Cepat (data kecil) | Sedang | Cepat | Sangat cepat |
| Kompleksitas | Sangat mudah | Sedang | Mudah | Mudah-sedang |
| Offline Support | Ya | Ya | Ya | Ya |
| Cocok Untuk | Pengaturan, preferensi | Data terstruktur, CRUD | Cache, data sederhana | Data besar, relasi |
| Popularitas | Sangat tinggi | Tinggi | Sedang | Sedang |
| Dukungan Web | Ya | Tidak (perlu sqflite_common_ffi) | Ya | Tidak |

## Keputusan Final

**Kombinasi yang dipilih:**
- **SharedPreferences** → untuk menyimpan preferensi tema (gelap/terang) dan waktu terakhir dibuka
- **SQLite (sqflite)** → untuk menyimpan data catatan (CRUD) secara persisten

## Alasan Teknis

### Mengapa SharedPreferences untuk Preferensi?
1. Data preferensi bersifat key-value sederhana (boolean untuk tema, string untuk waktu)
2. Tidak perlu query atau relasi antar data
3. API sangat sederhana dan mudah digunakan
4. Performanya cepat untuk data berukuran kecil

### Mengapa SQLite untuk Catatan?
1. Data catatan bersifat terstruktur (id, title, content, timestamps, dirty flag)
2. Memerlukan operasi CRUD lengkap (Create, Read, Update, Delete)
3. Perlu sorting berdasarkan kolom tertentu (updated_at)
4. Perlu query khusus (catatan dirty untuk sync)
5. SQLite adalah standar industri untuk penyimpanan lokal di mobile
6. Package `sqflite` memiliki dokumentasi dan komunitas yang besar

### Mengapa Bukan Hive atau ObjectBox?
- **Hive**: Bagus untuk kasus sederhana, tapi SQLite lebih cocok karena kita butuh query SQL (filter dirty notes, order by updated_at)
- **ObjectBox**: Sangat cepat tapi over-engineering untuk skala project ini, dan setup-nya lebih kompleks

## Aturan Konflik (Conflict Resolution)

**Strategi: Last Write Wins (LWW)**

Ketika ada konflik antara data lokal dan remote:
- Bandingkan field `updated_at` dari kedua versi
- Versi dengan `updated_at` yang lebih baru akan menang
- Versi lama akan ditimpa

Alasan memilih LWW:
1. Sederhana untuk diimplementasikan
2. Cukup untuk aplikasi catatan personal (single user)
3. Mudah dipahami oleh pengguna
4. Tidak memerlukan UI resolusi konflik yang kompleks
