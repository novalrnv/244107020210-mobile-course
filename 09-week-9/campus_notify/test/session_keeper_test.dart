import 'package:campus_notify/data/session_keeper.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late InMemoryTokenStore store;
  late FakeAuthRepository auth;
  late SessionKeeper keeper;

  setUp(() {
    store = InMemoryTokenStore();
    auth = FakeAuthRepository();
    keeper = SessionKeeper(tokenStore: store, authRepository: auth);
  });

  test('refresh berhasil mengganti access token dan mempertahankan refresh', () async {
    store.access = 'access-lama';
    store.refresh = 'refresh-valid';

    final renewed = await keeper.renewAccess();

    expect(renewed, 'access-renewed-1');
    expect(store.access, 'access-renewed-1');
    expect(store.refresh, 'refresh-valid');
    expect(store.clearCount, 0);
  });

  test('tanpa refresh token sesi dibersihkan', () async {
    store.access = 'access-lama';

    final renewed = await keeper.renewAccess();

    expect(renewed, isNull);
    expect(store.access, isNull);
    expect(store.clearCount, 1);
  });

  test('refresh ditolak server memaksa login ulang', () async {
    store.access = 'access-lama';
    store.refresh = 'refresh-kedaluwarsa';
    auth.failRefresh = true;

    final renewed = await keeper.renewAccess();

    expect(renewed, isNull);
    expect(store.access, isNull);
    expect(store.refresh, isNull);
    expect(store.clearCount, 1);
  });

  test('refresh hanya dipanggil sekali per percobaan', () async {
    store.refresh = 'refresh-valid';

    await keeper.renewAccess();
    await keeper.renewAccess();

    expect(auth.refreshCalls, 2);
  });
}
