# Perbandingan Solusi Penyimpanan Lokal di Flutter

Dokumen ini memuat perbandingan teknis antara **SharedPreferences**, **Hive / Hive CE**, **sqflite (Raw SQLite)**, dan **Drift (Typed Reactive SQLite)** untuk dua kebutuhan utama pada aplikasi **Flutter Offline Notes**:
1. **Preferensi Pengguna & Tema** (*Settings/Dark Mode*)
2. **CRUD Catatan** (*Offline-First, 1000+ Data, Sinkronisasi*)

---

## 1. Tabel Perbandingan 4 Solusi Penyimpanan Lokal

| Kriteria | **SharedPreferences** | **Hive / Hive CE** | **sqflite (Raw SQLite)** | **Drift (Reactive SQLite)** |
| :--- | :--- | :--- | :--- | :--- |
| **Model Data** | Key-Value primitif (XML / NSUserDefaults / plist) | NoSQL Box (Binary format) | Relasional (RDBMS SQL) | Relasional (RDBMS SQL berorientasi objek) |
| **Kompleksitas Query** | ❌ Sangat terbatas (hanya `get(key)`) | ⚠️ Dasar (filter linear di memori / index manual) | ✔️ Tinggi (WHERE, LIKE, FTS, agregasi, subquery) | ✔️ Sangat Tinggi (Type-safe query builder, Dart / SQL DSL) |
| **Kebutuhan Relasi (JOIN)** | ❌ Tidak mendukung relasi | ⚠️ Manual via ID lookup (tidak ada foreign key bawaan) | ✔️ Penuh (Foreign Key, JOIN, ON DELETE CASCADE) | ✔️ Penuh & Terstruktur (Type-safe joins, view, relations) |
| **Reaktivitas (Stream)** | ❌ Tidak ada bawaan (harus dibungkus state management) | ⚠️ `ValueListenable` / `watch()` per Box/Key | ❌ Manual (perlu trigger/event manual ke Provider/Bloc) | ✔️ Bawaan (`watch()`, `watchSingle()`, auto-update saat mutasi) |
| **Type-Safety** | ⚠️ Lemah (casting tipe data secara manual) | ⚠️ Parsial (butuh `TypeAdapter` & Type Casting) | ⚠️ Lemah (berbasis `Map<String, dynamic>`, raw string SQL) | ✔️ Sangat Kuat (Compile-time checked, auto-generated Dart classes) |
| **Ukuran Boilerplate** | ✔️ Sangat Rendah (Langsung pakai `getInstance()`) | ⚠️ Sedang (Registrasi adapter, anotasi `@HiveType`) | ⚠️ Sedang-Tinggi (Raw query, mapping Map ↔ Object manual) | ⚠️ Tinggi di awal (Build runner, skema Dart/SQL generation) |
| **Kemudahan Testing** | ✔️ Sangat Mudah (`setMockInitialValues`) | ⚠️ Sedang (Butuh mock box / direktori temporary disk) | ⚠️ Butuh FFI (`sqflite_common_ffi`) untuk unit test di VM | ✔️ Sangat Mudah (`NativeDatabase.memory()`, in-memory isolation) |

---

## 2. Analisis Trade-Off Setiap Pilihan

### A. SharedPreferences
* **Kelebihan**:
  - Nol konfigurasi skema dan tanpa proses migrasi data yang rumit.
  - Sangat cepat untuk membaca/menulis konfigurasi sederhana (tema gelap/terang, token autentikasi, status onboarding, timestamp terakhir dibuka).
* **Kekurangan / Trade-off**:
  - Seluruh file dibaca ke dalam memori RAM saat inisialisasi aplikasi.
  - Tidak dirancang untuk data koleksi besar atau data relasional (menyimpan daftar JSON panjang memboroskan RAM dan rawan korupsi data jika proses tulis terinterupsi).
  - Tidak mendukung operasi query, pencarian teks, ataupun pengurutan (*sorting*).

### B. Hive / Hive CE
* **Kelebihan**:
  - Performa baca/tulis dasar sangat cepat karena berbasis format biner lokal dan indeks in-memory.
  - Berdiri sendiri (pure Dart), tidak memerlukan library native SQLite C.
* **Kekurangan / Trade-off**:
  - **Memory Footprint**: Memuat seluruh key/value ke dalam memori RAM. Pada ribuan catatan panjang beserta metadata, konsumsi memori meningkat signifikan.
  - **Keterbatasan Query**: Operasi pencarian teks atau filter kategori harus memuat seluruh objek ke RAM lalu diproses dengan CPU aplikasi (`list.where(...)`).
  - **Skema & Migrasi**: Perubahan struktur model memerlukan pengelolaan `typeId` dan *default value* manual yang rentan kesalahan jika tidak konsisten.

### C. sqflite (Raw SQLite)
* **Kelebihan**:
  - Menggunakan engine SQLite bawaan sistem operasi yang teruji dan stabil.
  - Mendukung transaksi ACID, indeks multi-kolom, pagination (`LIMIT ... OFFSET`), dan pencarian teks efisien.
* **Kekurangan / Trade-off**:
  - **Raw SQL String**: Kesalahan pengetikan (*typo*) pada nama kolom atau sintaks SQL baru terdeteksi saat runtime.
  - **Boilerplate Manual**: Pengembang harus menulis fungsi serialisasi manual (`toMap` dan `fromMap`) untuk setiap entitas.
  - **Non-Reaktif**: Tidak menyediakan stream reaktif otomatis; pembaruan data harus diatur manual melalui state management (misal: `ref.invalidate(...)`).

### D. Drift (Typed SQLite)
* **Kelebihan**:
  - **Compile-Time Safety**: Kesalahan query, nama kolom, atau tipe data diverifikasi langsung saat kompilasi.
  - **Reaktif**: Menyediakan `Stream<List<Note>>` yang otomatis memicu render ulang widget saat baris tabel berubah.
  - **Manajemen Migrasi**: Menyediakan API migrasi skema terstruktur serta *testing kit* untuk memverifikasi migrasi antar versi database.
* **Kekurangan / Trade-off**:
  - Memerlukan proses *code generation* (`build_runner`), yang menambah waktu *build*.
  - Kurva pembelajaran lebih tinggi untuk memahami DSL (Domain Specific Language) Drift.

---

## 3. Skema Penyimpanan untuk 1000+ Catatan (Offline-First)

Untuk menangani 1000+ catatan dengan kebutuhan sinkronisasi *offline-first* dan pencarian yang responsif, pendekatan database relasional berindeks adalah solusi terbaik.

### DDL Skema SQLite / Drift

```sql
-- Tabel Catatan Utama
CREATE TABLE notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id TEXT UNIQUE,               -- ID dari server (nullable jika dibuat saat offline)
    title TEXT NOT NULL,
    body TEXT NOT NULL DEFAULT '',
    is_pinned INTEGER NOT NULL DEFAULT 0, -- 0: false, 1: true
    is_deleted INTEGER NOT NULL DEFAULT 0,-- Soft delete flag (0: aktif, 1: dihapus)
    dirty INTEGER NOT NULL DEFAULT 1,     -- Flag sinkronisasi (1: perlu upload, 0: bersih)
    created_at INTEGER NOT NULL,          -- Epoch timestamp (milliseconds)
    updated_at INTEGER NOT NULL           -- Epoch timestamp (milliseconds)
);

-- Indexing untuk query tampilan daftar catatan & pagination cepat
CREATE INDEX idx_notes_active_updated 
ON notes (is_deleted, is_pinned DESC, updated_at DESC);

-- Indexing parsial untuk proses sinkronisasi cepat (tanpa table scan)
CREATE INDEX idx_notes_dirty 
ON notes (dirty) WHERE dirty = 1;
```

### Strategi Eksekusi Query pada Skala 1000+ Catatan

1. **Pagination (Lazy Loading / Infinite Scroll)**:
   ```sql
   SELECT id, title, substr(body, 1, 100) AS preview, updated_at, dirty 
   FROM notes 
   WHERE is_deleted = 0 
   ORDER BY is_pinned DESC, updated_at DESC 
   LIMIT 20 OFFSET 0;
   ```
   *Manfaat*: Hanya memuat 20 item yang sedang ditampilkan ke RAM, bukan seluruh 1000+ catatan.

2. **Sinkronisasi Efisien (Delta Sync)**:
   ```sql
   SELECT * FROM notes WHERE dirty = 1 AND is_deleted = 0;
   ```
   *Manfaat*: Indeks `idx_notes_dirty` memungkinkan SQLite langsung mengambil data yang belum tersinkron tanpa membaca baris lainnya.

---

## 4. Rekomendasi Final

| Kategori Kebutuhan | Rekomendasi Teknologi | Alasan Utama Pemilihan |
| :--- | :--- | :--- |
| **Preferensi Tema & Pengaturan Aplikasi** | **SharedPreferences** | • **Zero Boilerplate**: Cukup untuk menyimpan key-value sederhana (`is_dark_mode`, `last_opened`).<br>• **Akses Cepat**: Nilai langsung dibaca dari cache memori tanpa overhead engine database.<br>• **Testing Mudah**: Dapat dimock secara instan dengan `setMockInitialValues()`. |
| **CRUD Catatan (Offline-First, 1000+ Data)** | **Drift** *(atau **sqflite** jika menghindari code-gen)* | • **ACID & Indexing**: Menjamin integritas data saat transaksi batch/sinkronisasi serta pencarian cepat.<br>• **Efisien Memori**: Mendukung paging (`LIMIT/OFFSET`), menjaga penggunaan RAM tetap stabil.<br>• **Type Safety & Reaktivitas (Drift)**: Menghindari error runtime saat refactor model dan menyediakan auto-updating stream ke UI. |
