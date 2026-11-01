import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'messaging/push_service.dart';
import 'providers/app_providers.dart';
import 'providers/auth_provider.dart';
import 'providers/inbox_provider.dart';

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
  final push = container.read(pushServiceProvider);
  await push.attach(
    go: (route) {
      final loggedIn = container.read(authStateProvider).value ?? false;
      if (!loggedIn) {
        container.read(deepLinkBufferProvider).put(route);
        return;
      }
      router.go(route);
    },
  );

  // Sesi yang sudah aktif saat aplikasi dibuka: ID perangkat perlu dikirim
  // ulang karena registrasi di attach() berjalan tanpa konteks user.
  if (container.read(authStateProvider).value ?? false) {
    await push.syncDeviceToBackend();
  }
}

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Notifikasi yang datang saat aplikasi di background ditulis oleh isolate
    // lain. Daftar dibaca ulang ketika aplikasi kembali ke depan, kalau tidak
    // notifikasi baru tidak akan terlihat sampai aplikasi dibuka ulang.
    if (state == AppLifecycleState.resumed) {
      ref.read(inboxProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Deep link yang tertahan selama login dikirim setelah sesi aktif.
    ref.listen<AsyncValue<bool>>(authStateProvider, (previous, next) {
      final wasLoggedIn = previous?.value ?? false;
      final isLoggedIn = next.value ?? false;
      if (!wasLoggedIn && isLoggedIn) {
        // ID perangkat dikirim ulang atas nama user yang baru login.
        ref.read(pushServiceProvider).syncDeviceToBackend();
        ref.read(inboxProvider.notifier).refresh();
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
