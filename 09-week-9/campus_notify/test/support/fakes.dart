import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/token_store.dart';

/// Token store palsu: tidak menyentuh Keychain/Keystore, jadi bisa dipakai
/// di unit test dan widget test.
class InMemoryTokenStore implements TokenStore {
  String? access;
  String? refresh;
  int clearCount = 0;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
    clearCount++;
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.failLogin = false, this.failRefresh = false});

  bool failLogin;
  bool failRefresh;
  int refreshCalls = 0;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (failLogin) {
      throw const AuthException('Email atau kata sandi tidak valid');
    }
    return AuthSession(
      access: 'access-$email',
      refresh: 'refresh-$email',
    );
  }

  @override
  Future<String> refresh(String refreshToken) async {
    refreshCalls++;
    if (failRefresh) {
      throw const AuthException('Refresh token ditolak server');
    }
    return 'access-renewed-$refreshCalls';
  }
}
