import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'messaging/push_service.dart';
import 'providers/app_providers.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseReady = await PushService.ensureFirebase();
  if (firebaseReady) {
    PushService.registerBackgroundHandler();
  }

  final container = ProviderContainer(
    overrides: [firebaseReadyProvider.overrideWithValue(firebaseReady)],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CampusNotifyApp(),
    ),
  );

  // Push didaftarkan setelah UI hidup supaya getInitialMessage bisa langsung
  // menavigasi tanpa menunggu frame pertama.
  final router = container.read(routerProvider);
  await container.read(pushServiceProvider).attach(
    go: (route) {
      final loggedIn = container.read(authStateProvider).value ?? false;
      if (!loggedIn) {
        container.read(deepLinkBufferProvider).put(route);
        return;
      }
      router.go(route);
    },
  );
}

class CampusNotifyApp extends ConsumerWidget {
  const CampusNotifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Deep link yang tertahan selama login dikirim setelah sesi aktif.
    ref.listen<AsyncValue<bool>>(authStateProvider, (previous, next) {
      final wasLoggedIn = previous?.value ?? false;
      final isLoggedIn = next.value ?? false;
      if (!wasLoggedIn && isLoggedIn) {
        final pending = ref.read(deepLinkBufferProvider).take();
        if (pending != null) router.go(pending);
      }
    });

    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
