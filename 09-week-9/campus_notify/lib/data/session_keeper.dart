import 'auth_repository.dart';
import 'token_store.dart';

/// Satu-satunya tempat access token diperbarui.
///
/// Dipisah dari interceptor Dio supaya bisa diuji tanpa jaringan:
/// masuk dengan refresh token, keluar dengan access token baru atau `null`
/// (artinya sesi mati dan pengguna harus login ulang).
class SessionKeeper {
  SessionKeeper({
    required TokenStore tokenStore,
    required AuthRepository authRepository,
  }) : _store = tokenStore,
       _auth = authRepository;

  final TokenStore _store;
  final AuthRepository _auth;

  /// Mengembalikan access token baru, atau `null` bila refresh gagal.
  ///
  /// Saat gagal, seluruh token dihapus: menyisakan refresh token yang sudah
  /// mati hanya akan menghasilkan 401 berulang di request berikutnya.
  Future<String?> renewAccess() async {
    final refresh = await _store.readRefresh();
    if (refresh == null || refresh.isEmpty) {
      await _store.clear();
      return null;
    }

    try {
      final access = await _auth.refresh(refresh);
      await _store.save(access: access, refresh: refresh);
      return access;
    } on Object {
      await _store.clear();
      return null;
    }
  }
}
