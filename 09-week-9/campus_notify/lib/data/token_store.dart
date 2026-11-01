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
class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  @override
  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  @override
  Future<String?> readAccess() => _storage.read(key: _accessKey);

  @override
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  @override
  Future<void> clear() => _storage.deleteAll();
}
