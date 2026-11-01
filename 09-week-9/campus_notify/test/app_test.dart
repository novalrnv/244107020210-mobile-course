import 'package:campus_notify/main.dart';
import 'package:campus_notify/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

Widget _app(InMemoryTokenStore store) {
  return ProviderScope(
    overrides: [
      tokenStoreProvider.overrideWithValue(store),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    ],
    child: const CampusNotifyApp(),
  );
}

void main() {
  testWidgets('tanpa sesi, guard route menahan di halaman login', (
    tester,
  ) async {
    await tester.pumpWidget(_app(InMemoryTokenStore()));
    await tester.pumpAndSettle();

    expect(find.text('Campus Notify'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('login membuka beranda dan menyimpan token', (tester) async {
    final store = InMemoryTokenStore();
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'mhs@polinema.ac.id',
    );
    await tester.enterText(find.byType(TextFormField).last, 'rahasia123');

    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Pengumuman terbaru'), findsOneWidget);
    expect(store.access, isNotNull);
    expect(store.refresh, isNotNull);
  });
}
