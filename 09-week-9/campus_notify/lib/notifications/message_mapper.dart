import '../messaging/notification_route.dart';
import 'inbox_item.dart';

/// Membentuk item kotak masuk dari isi pesan FCM.
///
/// Dipisah dari `RemoteMessage` supaya bisa diuji tanpa Firebase. Parameter
/// sengaja primitif: judul, isi, data, dan waktu terima.
InboxItem? inboxItemFromPayload({
  required String? messageId,
  required String? title,
  required String? body,
  required Map<String, dynamic> data,
  required DateTime receivedAt,
}) {
  // Sebagian backend hanya mengirim data tanpa blok notification.
  final resolvedTitle = (title ?? data['title']?.toString() ?? '').trim();
  if (resolvedTitle.isEmpty) return null;

  final resolvedBody = (body ?? data['body']?.toString() ?? '').trim();
  final route = routeFromMessage(data);

  return InboxItem(
    id: _resolveId(
      messageId: messageId,
      title: resolvedTitle,
      body: resolvedBody,
      route: route,
    ),
    title: resolvedTitle,
    body: resolvedBody,
    route: route,
    receivedAt: receivedAt,
  );
}

/// `messageId` dari FCM sudah unik dan stabil, jadi dipakai lebih dulu.
///
/// Cadangannya memakai hash deterministik buatan sendiri, bukan
/// `String.hashCode`: hashCode bisa berbeda antar isolate, sehingga pesan yang
/// sama bisa tercatat dua kali oleh UI dan handler background.
String _resolveId({
  required String? messageId,
  required String title,
  required String body,
  required String route,
}) {
  final candidate = messageId?.trim() ?? '';
  if (candidate.isNotEmpty) return candidate;

  var hash = 0x811c9dc5;
  for (final unit in '$title|$body|$route'.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return 'local-${hash.toRadixString(16)}';
}
