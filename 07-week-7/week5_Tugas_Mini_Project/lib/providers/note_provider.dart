import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../repositories/note_repository.dart';
import '../database/database_helper.dart';

// Provider untuk repository (bisa di-override saat testing)
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return LocalNoteRepository(DatabaseHelper.instance);
});

// Provider utama untuk daftar catatan
final noteListProvider =
    StateNotifierProvider<NoteListNotifier, AsyncValue<List<Note>>>((ref) {
  final repository = ref.watch(noteRepositoryProvider);
  return NoteListNotifier(repository);
});

class NoteListNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final NoteRepository _repository;
  final FakeRemoteRepository _remoteRepo = FakeRemoteRepository();

  NoteListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  // Muat semua catatan dari database lokal (cache-first)
  Future<void> loadNotes() async {
    try {
      state = const AsyncValue.loading();
      final notes = await _repository.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Tambah catatan baru
  Future<void> addNote(String title, String content) async {
    try {
      final now = DateTime.now();
      final note = Note(
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        isDirty: true, // tandai sebagai dirty (belum di-sync)
      );
      await _repository.insertNote(note);
      await loadNotes();
    } catch (e) {
      await loadNotes();
    }
  }

  // Update catatan yang sudah ada
  Future<void> updateNote(Note note, String title, String content) async {
    try {
      final updatedNote = note.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
        isDirty: true, // tandai sebagai dirty lagi
      );
      await _repository.updateNote(updatedNote);
      await loadNotes();
    } catch (e) {
      await loadNotes();
    }
  }

  // Hapus catatan
  Future<void> deleteNote(int id) async {
    try {
      await _repository.deleteNote(id);
      await loadNotes();
    } catch (e) {
      await loadNotes();
    }
  }

  // Sync catatan yang dirty ke server (simulasi)
  Future<int> syncNotes() async {
    try {
      final dirtyNotes = await _repository.getDirtyNotes();

      if (dirtyNotes.isEmpty) return 0;

      int syncCount = 0;
      for (final note in dirtyNotes) {
        // Upload ke remote (simulasi)
        final success = await _remoteRepo.uploadNote(note);
        if (success) {
          // Tandai sebagai clean di lokal
          await _repository.markAsClean(note.id!);
          syncCount++;
        }
      }

      await loadNotes();
      return syncCount;
    } catch (e) {
      await loadNotes();
      return 0;
    }
  }

  // Hitung jumlah catatan dirty
  Future<int> getDirtyCount() async {
    final dirtyNotes = await _repository.getDirtyNotes();
    return dirtyNotes.length;
  }
}
