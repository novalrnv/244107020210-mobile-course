import 'package:flutter_test/flutter_test.dart';
import 'package:offline_notes/models/note.dart';
import 'package:offline_notes/repositories/note_repository.dart';
import 'package:offline_notes/providers/note_provider.dart';

// Repository palsu (fake) untuk testing
class FakeNoteRepository implements NoteRepository {
  final List<Note> _notes = [];
  int _nextId = 1;

  @override
  Future<List<Note>> getAllNotes() async {
    // Urutkan berdasarkan updatedAt terbaru (sama seperti implementasi asli)
    final sorted = List<Note>.from(_notes)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  @override
  Future<Note?> getNoteById(int id) async {
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Note> insertNote(Note note) async {
    final newNote = note.copyWith(id: _nextId++);
    _notes.add(newNote);
    return newNote;
  }

  @override
  Future<void> updateNote(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
    }
  }

  @override
  Future<void> deleteNote(int id) async {
    _notes.removeWhere((n) => n.id == id);
  }

  @override
  Future<List<Note>> getDirtyNotes() async {
    return _notes.where((n) => n.isDirty).toList();
  }

  @override
  Future<void> markAsClean(int id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notes[index] = _notes[index].copyWith(isDirty: false);
    }
  }

  @override
  Future<void> markAllAsClean() async {
    for (var i = 0; i < _notes.length; i++) {
      _notes[i] = _notes[i].copyWith(isDirty: false);
    }
  }
}

void main() {
  group('NoteListNotifier Test dengan FakeRepository', () {
    late FakeNoteRepository fakeRepo;
    late NoteListNotifier notifier;

    setUp(() {
      fakeRepo = FakeNoteRepository();
      notifier = NoteListNotifier(fakeRepo);
    });

    test('addNote berhasil menambah catatan', () async {
      // Tunggu loading awal selesai
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.addNote('Catatan Pertama', 'Isi catatan pertama');

      // Cek state berisi 1 catatan
      final state = notifier.state;
      expect(state.hasValue, true);
      expect(state.value!.length, 1);
      expect(state.value!.first.title, 'Catatan Pertama');
      expect(state.value!.first.content, 'Isi catatan pertama');
      expect(state.value!.first.isDirty, true);
    });

    test('deleteNote berhasil menghapus catatan', () async {
      await Future.delayed(const Duration(milliseconds: 100));

      // Tambah dulu
      await notifier.addNote('Catatan Hapus', 'Akan dihapus');
      expect(notifier.state.value!.length, 1);

      // Ambil id catatan
      final noteId = notifier.state.value!.first.id!;

      // Hapus
      await notifier.deleteNote(noteId);
      expect(notifier.state.value!.length, 0);
    });

    test('updateNote berhasil mengubah catatan', () async {
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.addNote('Judul Lama', 'Konten lama');
      final note = notifier.state.value!.first;

      await notifier.updateNote(note, 'Judul Baru', 'Konten baru');

      expect(notifier.state.value!.first.title, 'Judul Baru');
      expect(notifier.state.value!.first.content, 'Konten baru');
    });

    test('syncNotes menandai catatan sebagai clean', () async {
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.addNote('Sync Test', 'Catatan untuk sync');

      // Sebelum sync, catatan harus dirty
      expect(notifier.state.value!.first.isDirty, true);

      // Lakukan sync
      final syncCount = await notifier.syncNotes();

      expect(syncCount, 1);
      // Setelah sync, catatan harus clean
      expect(notifier.state.value!.first.isDirty, false);
    });

    test('getDirtyCount menghitung catatan yang belum sync', () async {
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.addNote('Dirty 1', 'Isi 1');
      await notifier.addNote('Dirty 2', 'Isi 2');

      final dirtyCount = await notifier.getDirtyCount();
      expect(dirtyCount, 2);

      // Sync semua
      await notifier.syncNotes();

      final dirtyCountAfter = await notifier.getDirtyCount();
      expect(dirtyCountAfter, 0);
    });
  });
}
