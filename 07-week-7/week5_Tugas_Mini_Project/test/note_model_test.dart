import 'package:flutter_test/flutter_test.dart';
import 'package:offline_notes/models/note.dart';

void main() {
  group('Note Model Test', () {
    test('toMap menghasilkan Map yang benar', () {
      final note = Note(
        id: 1,
        title: 'Test Judul',
        content: 'Test isi catatan',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        updatedAt: DateTime(2024, 1, 15, 11, 0),
        isDirty: true,
      );

      final map = note.toMap();

      expect(map['id'], 1);
      expect(map['title'], 'Test Judul');
      expect(map['content'], 'Test isi catatan');
      expect(map['created_at'], '2024-01-15T10:30:00.000');
      expect(map['updated_at'], '2024-01-15T11:00:00.000');
      expect(map['is_dirty'], 1);
    });

    test('fromMap membuat Note yang benar dari Map', () {
      final map = {
        'id': 2,
        'title': 'Catatan Dua',
        'content': 'Isi catatan kedua',
        'created_at': '2024-02-20T09:00:00.000',
        'updated_at': '2024-02-20T09:30:00.000',
        'is_dirty': 0,
      };

      final note = Note.fromMap(map);

      expect(note.id, 2);
      expect(note.title, 'Catatan Dua');
      expect(note.content, 'Isi catatan kedua');
      expect(note.createdAt, DateTime(2024, 2, 20, 9, 0));
      expect(note.updatedAt, DateTime(2024, 2, 20, 9, 30));
      expect(note.isDirty, false);
    });

    test('copyWith mengubah field yang ditentukan saja', () {
      final note = Note(
        id: 1,
        title: 'Judul Awal',
        content: 'Konten awal',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isDirty: false,
      );

      final updated = note.copyWith(
        title: 'Judul Baru',
        isDirty: true,
      );

      // Field yang diubah
      expect(updated.title, 'Judul Baru');
      expect(updated.isDirty, true);

      // Field yang tidak diubah tetap sama
      expect(updated.id, 1);
      expect(updated.content, 'Konten awal');
      expect(updated.createdAt, DateTime(2024, 1, 1));
    });

    test('toMap lalu fromMap menghasilkan data yang konsisten', () {
      final original = Note(
        id: 5,
        title: 'Round Trip',
        content: 'Tes round trip konversi',
        createdAt: DateTime(2024, 6, 15, 14, 30),
        updatedAt: DateTime(2024, 6, 15, 15, 0),
        isDirty: true,
      );

      final map = original.toMap();
      final restored = Note.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.content, original.content);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
      expect(restored.isDirty, original.isDirty);
    });
  });
}
