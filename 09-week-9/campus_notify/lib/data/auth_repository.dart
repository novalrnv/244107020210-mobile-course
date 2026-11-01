class AuthSession {
  const AuthSession({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

/// Error yang pesannya aman ditampilkan ke pengguna.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Mock auth provider.
///
/// Bentuk API-nya sengaja dibuat sama dengan Firebase Auth: satu titik masuk
/// yang mengembalikan sesi berisi token. Untuk pindah ke Firebase cukup ganti
/// isi [login] dengan `FirebaseAuth.instance.signInWithEmailAndPassword` dan
/// ambil `await user.getIdToken()` sebagai access token. Sisanya (secure
/// storage, interceptor 401, guard route) tidak perlu berubah.
class AuthRepository {
  const AuthRepository();

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final normalized = email.trim().toLowerCase();
    if (!normalized.contains('@') || password.length < 6) {
      throw const AuthException('Email atau kata sandi tidak valid');
    }

    // Simulasi JWT. Di produksi token dibuat server, bukan di klien.
    return AuthSession(
      access: 'mock-access-for-$normalized',
      refresh: 'mock-refresh-for-$normalized',
    );
  }

  /// Menukar refresh token dengan access token baru.
  ///
  /// Di produksi ini panggilan `POST /auth/refresh` dengan refresh token di
  /// body (bukan query string, agar tidak tercatat di log server/proxy).
  Future<String> refresh(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (refreshToken.isEmpty) {
      throw const AuthException('Refresh token hilang');
    }
    return 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
  }
}
