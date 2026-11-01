/// Satu sumber kebenaran untuk semua path.
///
/// GoRouter dan payload deep link FCM mengambil string dari sini supaya
/// keduanya tidak pernah berbeda (mis. `/pengumuman/3` vs `pengumuman/3`).
class AppRoutes {
  const AppRoutes._();

  static const login = '/login';
  static const home = '/';
  static const debug = '/debug';
  static const inbox = '/notifikasi';

  /// Pola untuk deklarasi GoRoute.
  static const announcementPattern = '/pengumuman/:id';

  /// Path konkret untuk navigasi dan payload notifikasi.
  static String announcement(String id) => '/pengumuman/$id';
}
