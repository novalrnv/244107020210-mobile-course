import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'inbox_item.dart';

/// Penyimpanan kotak masuk notifikasi.
///
/// Dipisah menjadi antarmuka supaya bisa diganti versi in-memory saat unit
/// test, tanpa menyentuh platform channel.
abstract class InboxStorage {
  Future<List<InboxItem>> read();

  Future<void> write(List<InboxItem> items);
}

/// Versi nyata di atas SharedPreferences.
///
/// Memakai `SharedPreferencesAsync`, bukan `SharedPreferences.getInstance()`,
/// karena handler background FCM berjalan di isolate lain. Kelas cache biasa
/// menyimpan salinan di memori per isolate sehingga tulisan dari isolate
/// background tidak pernah terlihat oleh UI.
class PrefsInboxStorage implements InboxStorage {
  PrefsInboxStorage({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _key = 'inbox_items';

  final SharedPreferencesAsync _prefs;

  @override
  Future<List<InboxItem>> read() async {
    final raw = await _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <InboxItem>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <InboxItem>[];

      return decoded
          .map(InboxItem.fromJson)
          .whereType<InboxItem>()
          .toList(growable: false);
    } on FormatException {
      // Data rusak lebih baik dibuang daripada membuat aplikasi gagal dibuka.
      return const <InboxItem>[];
    }
  }

  @override
  Future<void> write(List<InboxItem> items) async {
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    await _prefs.setString(_key, encoded);
  }
}

/// Operasi tingkat tinggi yang dipakai UI maupun handler background.
class InboxRepository {
  InboxRepository({InboxStorage? storage})
    : _storage = storage ?? PrefsInboxStorage();

  final InboxStorage _storage;

  Future<List<InboxItem>> all() async {
    final items = await _storage.read();
    // Terbaru di atas, supaya pengumuman terakhir langsung terlihat.
    return items.toList()
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  }

  /// Menambah notifikasi. ID yang sama tidak dimasukkan dua kali: pesan yang
  /// sama bisa datang lewat `onMessage` dan `onMessageOpenedApp`.
  Future<List<InboxItem>> add(InboxItem item) async {
    final items = await _storage.read();
    if (items.any((existing) => existing.id == item.id)) {
      return await all();
    }

    final updated = <InboxItem>[...items, item];
    await _storage.write(updated);
    return await all();
  }

  /// Dipakai saat notifikasi dibaca: item hilang dari daftar.
  Future<List<InboxItem>> remove(String id) async {
    final items = await _storage.read();
    final updated = items.where((item) => item.id != id).toList();
    if (updated.length != items.length) {
      await _storage.write(updated);
    }
    return await all();
  }

  Future<List<InboxItem>> clear() async {
    await _storage.write(const <InboxItem>[]);
    return const <InboxItem>[];
  }
}
