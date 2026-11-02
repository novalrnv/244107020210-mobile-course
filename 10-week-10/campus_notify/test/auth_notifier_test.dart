import 'package:campus_notify/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late InMemoryTokenStore store;
  late FakeAuthRepository auth;
  late ProviderContainer container;

  setUp(() {
    store = InMemoryTokenStore();
    auth = FakeAuthRepository();
    container = ProviderContainer.test(
      overrides: [
        tokenStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
  });

  test('tanpa token di secure storage, status belum login', () async {
    expect(await container.read(authStateProvider.future), isFalse);
  });

  test('token tersimpan membuat status login', () async {
    store.access = 'access-lama';
    expect(await container.read(authStateProvider.future), isTrue);
  });

  test('login menyimpan access dan refresh', () async {
    await container
        .read(authStateProvider.notifier)
        .login(email: 'mhs@polinema.ac.id', password: 'rahasia123');

    expect(container.read(authStateProvider).value, isTrue);
    expect(store.access, 'access-mhs@polinema.ac.id');
    expect(store.refresh, 'refresh-mhs@polinema.ac.id');
  });

  test('login gagal tidak menyimpan token apa pun', () async {
    auth.failLogin = true;

    await container
        .read(authStateProvider.notifier)
        .login(email: 'salah', password: '123');

    expect(container.read(authStateProvider).hasError, isTrue);
    expect(container.read(authStateProvider).value, isNot(true));
    expect(store.access, isNull);
    expect(store.refresh, isNull);
  });

  test('logout menghapus token dan mengembalikan status belum login', () async {
    store.access = 'access-lama';
    store.refresh = 'refresh-lama';
    await container.read(authStateProvider.future);

    await container.read(authStateProvider.notifier).logout();

    expect(store.access, isNull);
    expect(store.refresh, isNull);
    expect(await container.read(authStateProvider.future), isFalse);
  });
}
