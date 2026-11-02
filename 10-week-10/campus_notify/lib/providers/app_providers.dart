import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/announcement_repository.dart';
import '../messaging/push_service.dart';
import '../pages/announcement_page.dart';
import '../pages/debug_page.dart';
import '../pages/home_page.dart';
import '../pages/inbox_page.dart';
import '../pages/login_page.dart';
import '../routes.dart';
import 'auth_provider.dart';
import 'inbox_provider.dart';

/// Diisi dari `main()` setelah `Firebase.initializeApp()` dicoba.
/// Default `false` supaya aplikasi tetap jalan tanpa google-services.json.
final firebaseReadyProvider = Provider<bool>((ref) => false);

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => const AnnouncementRepository(),
);

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(
    httpClient: ref.watch(dioProvider),
    firebaseReady: ref.watch(firebaseReadyProvider),
    inbox: ref.watch(inboxRepositoryProvider),
    // Notifikasi bisa ditulis dari isolate background, jadi UI perlu diminta
    // membaca ulang penyimpanan setiap kali ada perubahan.
    onInboxChanged: () => ref.read(inboxProvider.notifier).refresh(),
  );
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Deep link yang datang saat pengguna belum login.
///
/// Tanpa buffer ini, klik notifikasi ketika sesi habis akan dibuang oleh
/// guard route dan pengguna mendarat di beranda, bukan di pengumuman.
class DeepLinkBuffer {
  String? _pending;

  bool get hasPending => _pending != null;

  void put(String route) => _pending = route;

  String? take() {
    final value = _pending;
    _pending = null;
    return value;
  }
}

final deepLinkBufferProvider = Provider<DeepLinkBuffer>(
  (ref) => DeepLinkBuffer(),
);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);

  // GoRouter hanya tahu state auth berubah lewat listenable ini.
  ref.listen<AsyncValue<bool>>(authStateProvider, (previous, next) {
    refresh.value++;
  });

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      if (auth.isLoading && !auth.hasValue) return null;

      final loggedIn = auth.value ?? false;
      final atLogin = state.matchedLocation == AppRoutes.login;

      if (!loggedIn && !atLogin) return AppRoutes.login;
      if (loggedIn && atLogin) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(path: AppRoutes.debug, builder: (_, _) => const DebugPage()),
      GoRoute(path: AppRoutes.inbox, builder: (_, _) => const InboxPage()),
      GoRoute(
        path: AppRoutes.announcementPattern,
        builder: (_, state) =>
            AnnouncementPage(id: state.pathParameters['id'] ?? ''),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
