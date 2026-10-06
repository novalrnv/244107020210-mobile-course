# Dokumentasi Pengujian (Automated Testing)

Dokumen ini berisi dokumentasi dan hasil pengujian otomatis untuk aplikasi Offline Notes sesuai dengan ketentuan tugas poin 5:
> **5. Testing**: minimal 2 test lulus (1 unit test model + 1 test provider dengan repository palsu).

---

## 1. Rangkuman Pengujian

Sesuai spesifikasi, pengujian terdiri dari dua kelompok pengujian utama:
1. **Unit Test Model (`Note`)**: Menguji konversi serialisasi/deserialisasi (`toMap`, `fromMap`), integritas objek (`copyWith`), dan konsistensi data bolak-balik (round-trip).
2. **Provider Test dengan Fake Repository (`NoteListNotifier`)**: Menguji logika bisnis pada state notifier Riverpod tanpa ketergantungan pada SQLite fisik, menggunakan implementasi repository palsu (`FakeNoteRepository`).

Total skenario pengujian: **9 Test Case** (Melampaui syarat minimal 2 test), dengan status **100% Lulus (Passed)**.

---

## 2. Struktur Pengujian

```
test/
├── note_model_test.dart       # 4 Unit test untuk model data Note
└── note_provider_test.dart    # 5 Provider test menggunakan FakeNoteRepository
```

---

## 3. Detail Pengujian

### A. Unit Test Model (`test/note_model_test.dart`)

File ini menguji kebenaran pemetaan data antara objek Dart `Note` dengan tipe data SQLite `Map<String, dynamic>`.

```dart
void main() {
  group('Note Model Test', () {
    test('toMap menghasilkan Map yang benar', () { ... });
    test('fromMap membuat Note yang benar dari Map', () { ... });
    test('copyWith mengubah field yang ditentukan saja', () { ... });
    test('toMap lalu fromMap menghasilkan data yang konsisten', () { ... });
  });
}
```

#### Skenario yang Diuji:
| No | Nama Test | Tujuan | Hasil |
|---|---|---|---|
| 1 | `toMap menghasilkan Map yang benar` | Memastikan konversi field `id`, `title`, `content`, `created_at`, `updated_at`, dan boolean `is_dirty` menjadi integer (0/1) di SQLite sesuai. | **PASS** ✅ |
| 2 | `fromMap membuat Note yang benar dari Map` | Memastikan data map mentah dari SQLite berhasil dibaca kembali menjadi objek `Note` dengan parsing DateTime dan boolean yang tepat. | **PASS** ✅ |
| 3 | `copyWith mengubah field yang ditentukan saja` | Memastikan sifat immutability objek Note terjaga dan hanya field yang diperbarui yang mengalami perubahan nilai. | **PASS** ✅ |
| 4 | `toMap lalu fromMap menghasilkan data yang konsisten` | Menguji pengujian round-trip: data asli yang diubah ke Map dan dikonversi kembali ke Note memiliki nilai identik. | **PASS** ✅ |

---

### B. Provider Test dengan Repository Palsu (`test/note_provider_test.dart`)

Untuk menguji state management Riverpod secara terisolasi tanpa memerlukan database SQLite asli (yang bergantung pada native platform mobile), dibuat kelas `FakeNoteRepository` yang mengimplementasikan antarmuka `NoteRepository`:

```dart
class FakeNoteRepository implements NoteRepository {
  final List<Note> _notes = [];
  int _nextId = 1;

  @override
  Future<List<Note>> getAllNotes() async {
    final sorted = List<Note>.from(_notes)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }
  // Implementasi getNoteById, insertNote, updateNote, deleteNote, getDirtyNotes, markAsClean, markAllAsClean...
}
```

#### Skenario yang Diuji:
| No | Nama Test | Tujuan | Hasil |
|---|---|---|---|
| 1 | `addNote berhasil menambah catatan` | Memverifikasi pemanggilan `addNote` menambahkan catatan baru ke state dengan atribut `isDirty = true`. | **PASS** ✅ |
| 2 | `deleteNote berhasil menghapus catatan` | Memverifikasi catatan yang ada dapat dihapus dan state daftar catatan terupdate. | **PASS** ✅ |
| 3 | `updateNote berhasil mengubah catatan` | Memverifikasi perubahan judul/konten catatan tercermin pada state dan timestamp `updatedAt` terbarui. | **PASS** ✅ |
| 4 | `syncNotes menandai catatan sebagai clean` | Memverifikasi proses sinkronisasi mengubah catatan berstatus dirty menjadi clean (`isDirty = false`). | **PASS** ✅ |
| 5 | `getDirtyCount menghitung catatan yang belum sync` | Memverifikasi perhitungan jumlah catatan dirty sebelum dan sesudah proses sinkronisasi. | **PASS** ✅ |

---

## 4. Bukti Hasil Eksekusi Perintah `flutter test`

Berikut adalah output konsol terminal saat menjalankan perintah `flutter test`:

```text
PS C:\project-flutter\244107020210-mobile-course\07-week-7\week5_Tugas_Mini_Project> flutter test
00:00 +0: loading C:/project-flutter/244107020210-mobile-course/07-week-7/week5_Tugas_Mini_Project/test/note_model_test.dart
00:00 +0: C:/project-flutter/244107020210-mobile-course/07-week-7/week5_Tugas_Mini_Project/test/note_model_test.dart: Note Model Test toMap menghasilkan Map yang benar
00:00 +1: C:/project-flutter/244107020210-mobile-course/07-week-7/week5_Tugas_Mini_Project/test/note_model_test.dart: Note Model Test fromMap membuat Note yang benar dari Map
00:00 +2: C:/project-flutter/244107020210-mobile-course/07-week-7/week5_Tugas_Mini_Project/test/note_model_test.dart: Note Model Test copyWith mengubah field yang ditentukan saja
00:00 +3: C:/project-flutter/244107020210-mobile-course/07-week-7/week5_Tugas_Mini_Project/test/note_model_test.dart: Note Model Test toMap lalu fromMap menghasilkan data yang konsisten
00:00 +4: C:/project-flutter/244107020210-mobile-course/07-week-7/week5_Tugas_Mini_Project/test/note_provider_test.dart: NoteListNotifier Test dengan FakeRepository addNote berhasil menambah catatan
00:00 +5: C:/project-flutter/244107020210-mobile-course/07-week-7/week5_Tugas_Mini_Project/test/note_provider_test.dart: NoteListNotifier Test dengan FakeRepository deleteNote berhasil menghapus catatan
00:00 +6: C:/project-flutter/244107020210-mobile-course/07-week-7/week5_Tugas_Mini_Project/test/note_provider_test.dart: NoteListNotifier Test dengan FakeRepository updateNote berhasil mengubah catatan
00:00 +7: C:/project-flutter/244107020210-mobile-course/07-week-7/week5_Tugas_Mini_Project/test/note_provider_test.dart: NoteListNotifier Test dengan FakeRepository syncNotes menandai catatan sebagai clean
00:01 +8: C:/project-flutter/244107020210-mobile-course/07-week-7/week5_Tugas_Mini_Project/test/note_provider_test.dart: NoteListNotifier Test dengan FakeRepository getDirtyCount menghitung catatan yang belum sync
00:02 +9: All tests passed!
```

---

## 5. Kesimpulan Testing

1. **Unit Test Model**: Seluruh fungsi pemetaan data model `Note` berfungsi normal tanpa kesalahan konversi tipe data.
2. **Provider Test**: Pengujian state `NoteListNotifier` menggunakan fake repository membuktikan seluruh alur logika CRUD, dirty flag tracking, dan sinkronisasi berjalan sesuai spesifikasi tanpa dependensi eksternal.
3. Seluruh 9 skenario pengujian berstatus **All tests passed!** dalam waktu eksekusi kurang dari 3 detik.
