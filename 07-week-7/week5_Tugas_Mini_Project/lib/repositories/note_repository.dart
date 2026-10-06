import '../models/note.dart';
import '../database/database_helper.dart';

// Interface repository (abstrak) supaya bisa di-mock untuk testing
abstract class NoteRepository {
  Future<List<Note>> getAllNotes();
  Future<Note?> getNoteById(int id);
  Future<Note> insertNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(int id);
  Future<List<Note>> getDirtyNotes();
  Future<void> markAsClean(int id);
  Future<void> markAllAsClean();
}

// Implementasi lokal menggunakan SQLite
class LocalNoteRepository implements NoteRepository {
  final DatabaseHelper _dbHelper;

  LocalNoteRepository(this._dbHelper);

  @override
  Future<List<Note>> getAllNotes() async {
    final maps = await _dbHelper.getAllNotes();
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  @override
  Future<Note?> getNoteById(int id) async {
    final map = await _dbHelper.getNoteById(id);
    if (map == null) return null;
    return Note.fromMap(map);
  }

  @override
  Future<Note> insertNote(Note note) async {
    final map = note.toMap();
    map.remove('id'); // biar auto-increment
    final id = await _dbHelper.insertNote(map);
    return note.copyWith(id: id);
  }

  @override
  Future<void> updateNote(Note note) async {
    if (note.id == null) return;
    await _dbHelper.updateNote(note.toMap(), note.id!);
  }

  @override
  Future<void> deleteNote(int id) async {
    await _dbHelper.deleteNote(id);
  }

  @override
  Future<List<Note>> getDirtyNotes() async {
    final maps = await _dbHelper.getDirtyNotes();
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  @override
  Future<void> markAsClean(int id) async {
    await _dbHelper.markAsClean(id);
  }

  @override
  Future<void> markAllAsClean() async {
    await _dbHelper.markAllAsClean();
  }
}

// Repository palsu untuk simulasi server remote
class FakeRemoteRepository {
  final List<Note> _remoteNotes = [];

  // Simulasi upload catatan ke server
  Future<bool> uploadNote(Note note) async {
    // Simulasi delay jaringan
    await Future.delayed(const Duration(milliseconds: 500));

    // Cari apakah catatan sudah ada di server
    final index = _remoteNotes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      // Aturan konflik: Last Write Wins (yang punya updated_at lebih baru menang)
      if (note.updatedAt.isAfter(_remoteNotes[index].updatedAt)) {
        _remoteNotes[index] = note.copyWith(isDirty: false);
      }
    } else {
      _remoteNotes.add(note.copyWith(isDirty: false));
    }
    return true;
  }

  // Simulasi ambil semua catatan dari server
  Future<List<Note>> fetchAllNotes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_remoteNotes);
  }
}
