import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/session_keeper.dart';
import '../data/token_store.dart';

/// Token hanya lewat kelas ini, tidak pernah lewat SharedPreferences.
final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const AuthRepository(),
);

final sessionKeeperProvider = Provider<SessionKeeper>(
  (ref) => SessionKeeper(
    tokenStore: ref.watch(tokenStoreProvider),
    authRepository: ref.watch(authRepositoryProvider),
  ),
);

final dioProvider = Provider<Dio>(
  (ref) => buildApiClient(
    store: ref.watch(tokenStoreProvider),
    keeper: ref.watch(sessionKeeperProvider),
  ),
);

/// `true` = punya sesi aktif. Guard route membaca nilai ini.
final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null && token.isNotEmpty;
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await ref
          .read(tokenStoreProvider)
          .save(access: session.access, refresh: session.refresh);
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    ref.invalidateSelf();
  }
}
