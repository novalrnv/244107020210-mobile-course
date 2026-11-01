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
