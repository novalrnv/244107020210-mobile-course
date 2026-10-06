import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'offline_notes.db';
  static const String tableName = 'notes';

  // Singleton pattern
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_dirty INTEGER NOT NULL DEFAULT 1
          )
        ''');
      },
    );
  }

  // Ambil semua catatan, urut berdasarkan updated_at terbaru
  Future<List<Map<String, dynamic>>> getAllNotes() async {
    final db = await database;
    return await db.query(
      tableName,
      orderBy: 'updated_at DESC',
    );
  }

  // Ambil satu catatan berdasarkan id
  Future<Map<String, dynamic>?> getNoteById(int id) async {
    final db = await database;
    final results = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Tambah catatan baru
  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await database;
    return await db.insert(tableName, note);
  }

  // Update catatan
  Future<int> updateNote(Map<String, dynamic> note, int id) async {
    final db = await database;
    return await db.update(
      tableName,
      note,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Hapus catatan
  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Ambil catatan yang belum di-sync (dirty)
  Future<List<Map<String, dynamic>>> getDirtyNotes() async {
    final db = await database;
    return await db.query(
      tableName,
      where: 'is_dirty = ?',
      whereArgs: [1],
    );
  }

  // Tandai catatan sudah di-sync (clean)
  Future<void> markAsClean(int id) async {
    final db = await database;
    await db.update(
      tableName,
      {'is_dirty': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Tandai semua catatan sebagai clean
  Future<void> markAllAsClean() async {
    final db = await database;
    await db.update(
      tableName,
      {'is_dirty': 0},
    );
  }
}
