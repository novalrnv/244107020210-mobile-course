import '../routes.dart';

/// Mengubah `data` payload FCM menjadi path internal yang aman.
///
/// Fungsi murni: tanpa Firebase, tanpa BuildContext, sehingga bisa diuji
/// langsung di `flutter test`. Semua deep link wajib lewat sini agar payload
/// `pengumuman/3` (tanpa slash) tetap menjadi `/pengumuman/3`.
String routeFromMessage(Map<String, dynamic> data) {
  final raw = data['route'];
  return normalizeRoute(raw is String ? raw : null);
}

String normalizeRoute(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return AppRoutes.home;
  return value.startsWith('/') ? value : '/$value';
}

/// Payload notifikasi lokal membawa dua hal sekaligus:
/// path tujuan dan ID item kotak masuk.
///
/// Tanpa ID, aplikasi tidak tahu notifikasi mana yang harus dihapus saat
/// diketuk. Payload lama yang hanya berisi path tetap didukung agar notifikasi
/// yang sudah terlanjur muncul tidak membuka halaman yang salah.
class NotificationPayload {
  const NotificationPayload({required this.route, this.inboxId});

  final String route;
  final String? inboxId;

  static String encode({required String route, String? inboxId}) {
    final normalized = normalizeRoute(route);
    if (inboxId == null || inboxId.isEmpty) return normalized;
    return 'inbox:$inboxId|$normalized';
  }

  static NotificationPayload decode(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.startsWith('inbox:')) {
      final separator = value.indexOf('|');
      if (separator > 6) {
        final id = value.substring(6, separator);
        final route = value.substring(separator + 1);
        return NotificationPayload(
          route: normalizeRoute(route),
          inboxId: id,
        );
      }
    }
    return NotificationPayload(route: normalizeRoute(value));
  }
}
