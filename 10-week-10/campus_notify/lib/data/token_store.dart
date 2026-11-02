import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Kontrak penyimpanan token.
///
/// Dibuat abstrak supaya logika sesi bisa diuji tanpa plugin platform.
abstract class TokenStore {
  Future<void> save({required String access, required String refresh});

  Future<String?> readAccess();

  Future<String?> readRefresh();

  Future<void> clear();
}

/// Implementasi produksi: Keychain (iOS) / Keystore-backed storage (Android).
///
/// Token tidak pernah menyentuh SharedPreferences karena isinya tidak
/// terenkripsi dan bisa dibaca aplikasi lain pada perangkat yang di-root.
///
/// Setiap operasi dibatasi waktu. Tanpa batas ini, perangkat yang Keystore-nya
/// bermasalah (mis. `ServiceSpecificException` kode 7 / TRY_AGAIN setelah
/// aplikasi dipasang ulang) membuat `read()` tidak pernah selesai. Akibatnya
/// status login menggantung dan aplikasi berhenti di spinner selamanya.
class SecureTokenStore implements TokenStore {
  SecureTokenStore({
    FlutterSecureStorage? storage,
    this.timeout = const Duration(seconds: 5),
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Batas waktu tiap operasi penyimpanan.
  final Duration timeout;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  @override
  Future<void> save({required String access, required String refresh}) async {
    await _storage
        .write(key: _accessKey, value: access)
        .timeout(timeout);
    await _storage
        .write(key: _refreshKey, value: refresh)
        .timeout(timeout);
  }

  /// Mengembalikan `null` bila pembacaan gagal atau melewati batas waktu.
  ///
  /// Dianggap "belum login" supaya pengguna tetap bisa masuk. Menahan aplikasi
  /// di spinner hanya karena penyimpanan bermasalah jauh lebih buruk.
  @override
  Future<String?> readAccess() => _readSafely(_accessKey);

  @override
  Future<String?> readRefresh() => _readSafely(_refreshKey);

  @override
  Future<void> clear() async {
    try {
      await _storage.deleteAll().timeout(timeout);
    } on Object {
      // Sesi di memori tetap dibersihkan oleh pemanggil.
    }
  }

  Future<String?> _readSafely(String key) async {
    try {
      return await _storage.read(key: key).timeout(timeout);
    } on Object {
      return null;
    }
  }
}
