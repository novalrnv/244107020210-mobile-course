# Draf Awal AI

> **Status dokumen:** rekonstruksi draf pertama dari prompt di
> `01-prompt.md`. Kode ini **tidak** ada di `lib/` — yang berjalan adalah versi
> setelah perbaikan di `03-perbaikan-manual.md`. Disimpan sebagai bukti apa yang
> dihasilkan AI sebelum diperiksa.

## Yang dihasilkan

Satu file `lib/messaging/push_service.dart` berisi semua hal yang diminta
prompt: izin, token, tiga handler, topik, dan background handler. Ditambah
`pendingDeepLink` sebagai variabel global.

```dart
// VERSI AWAL — JANGAN DIPAKAI
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _local = FlutterLocalNotificationsPlugin();
String? pendingDeepLink;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // catat saja
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true, badge: true, sound: true,
    announcement: false, carPlay: false, criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _local.initialize(
    const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      pendingDeepLink = response.payload;
    },
  );
}

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
}

void listenForeground(void Function(String route) go) {
  FirebaseMessaging.onMessage.listen((message) async {
    final route = message.data['route'] ?? '/';
    const androidDetails = AndroidNotificationDetails(
      'pengumuman', 'Pengumuman Kampus',
      importance: Importance.high, priority: Priority.high,
    );
    await _local.show(
      message.hashCode,
      message.notification?.title ?? 'Pengumuman',
      message.notification?.body ?? '',
      const NotificationDetails(android: androidDetails),
      payload: route,
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(message.data['route'] ?? '/');
  });
}

Future<void> handleTerminated(void Function(String route) go) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) go(initial.data['route'] ?? '/');
  if (pendingDeepLink != null) go(pendingDeepLink!);
}
```

## Hasil pemeriksaan pertama

`flutter analyze` pada seluruh project (output Prompt 1 **dan** Prompt 2)
langsung menolak draf ini:

```
error - The type 'DioExceptionType' isn't exhaustively matched by the switch
        cases since it doesn't match the pattern 'DioExceptionType.transformTimeout'
        - lib\data\api_errors.dart
info  - Use an initializing formal to assign a parameter to a field.
        - lib\data\session_keeper.dart:11
info  - 'onTokenRefresh' is deprecated. Use onRegistered instead.
        - lib\messaging\push_service.dart:130
info  - 'getToken' is deprecated. Use register() and onRegistered instead.
        - lib\messaging\push_service.dart:193
warning - Unused import: 'routes.dart'.
        - lib\main.dart:7
```

Empat kategori masalah berbeda: **compile error** (versi paket berubah),
**API deprecated**, **lint gaya**, dan **perilaku yang salah meski tidak
dilaporkan analyzer**. Kategori terakhir yang paling berbahaya — lihat
`03-perbaikan-manual.md`.
