import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/api_client.dart';
import '../data/api_errors.dart';
import '../notifications/inbox_store.dart';
import '../notifications/message_mapper.dart';
import 'notification_route.dart';

/// Handler background wajib fungsi top-level.
///
/// Firebase menjalankannya di isolate terpisah, jadi tidak ada BuildContext,
/// tidak ada Riverpod, dan tidak ada state aplikasi. Satu-satunya yang bisa
/// dilakukan adalah menulis langsung ke penyimpanan, di sini ke kotak masuk.
///
/// `DartPluginRegistrant.ensureInitialized()` wajib dipanggil lebih dulu:
/// tanpa itu plugin SharedPreferences belum terdaftar di isolate ini dan
/// penulisan gagal diam-diam.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();

  final item = inboxItemFromPayload(
    messageId: message.messageId,
    title: message.notification?.title,
    body: message.notification?.body,
    data: message.data,
    receivedAt: DateTime.now(),
  );

  if (item == null) return;
  await InboxRepository().add(item);
}

/// Status yang ditampilkan di halaman Debug. Token selalu dipotong.
class PushStatus {
  const PushStatus({
    this.firebaseReady = false,
    this.permissionGranted = false,
    this.tokenPreview,
    this.tokenUpdatedAt,
    this.lastSync,
    this.subscribedToTopic = false,
  });

  final bool firebaseReady;
  final bool permissionGranted;
  final String? tokenPreview;
  final DateTime? tokenUpdatedAt;
  final String? lastSync;
  final bool subscribedToTopic;

  PushStatus copyWith({
    bool? permissionGranted,
    String? tokenPreview,
    DateTime? tokenUpdatedAt,
    String? lastSync,
    bool? subscribedToTopic,
  }) {
    return PushStatus(
      firebaseReady: firebaseReady,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      tokenPreview: tokenPreview ?? this.tokenPreview,
      tokenUpdatedAt: tokenUpdatedAt ?? this.tokenUpdatedAt,
      lastSync: lastSync ?? this.lastSync,
      subscribedToTopic: subscribedToTopic ?? this.subscribedToTopic,
    );
  }
}

/// Hanya 12 karakter pertama yang boleh tampil, sisanya dipotong.
/// Token penuh tidak pernah ditulis ke log maupun screenshot.
String maskToken(String token) {
  if (token.length <= 12) {
    return '${token.substring(0, token.length ~/ 2)}...';
  }
  return '${token.substring(0, 12)}...';
}

class PushService {
  PushService({
    required Dio httpClient,
    bool firebaseReady = false,
    this.inbox,
    this.onInboxChanged,
  }) : _dio = httpClient,
       _firebaseReady = firebaseReady {
    _status.value = PushStatus(firebaseReady: firebaseReady);
  }

  static const topic = 'pengumuman-kampus';
  static const _channelId = 'pengumuman';

  final Dio _dio;
  final bool _firebaseReady;

  /// Penyimpanan kotak masuk. `null` di unit test yang tidak menguji inbox.
  final InboxRepository? inbox;

  /// Memberi tahu UI bahwa isi kotak masuk berubah. PushService tidak tahu
  /// Riverpod, jadi penyegaran diserahkan ke pemanggil.
  final VoidCallback? onInboxChanged;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<PushStatus> _status = ValueNotifier(const PushStatus());
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  ValueListenable<PushStatus> get status => _status;

  bool get firebaseReady => _firebaseReady;

  void Function(String route)? _go;
  bool _attached = false;
  bool _localReady = false;

  /// ID perangkat terakhir yang diterima dari `onRegistered`.
  ///
  /// Disimpan supaya bisa dikirim ulang setelah pengguna login: registrasi
  /// berjalan di [attach] sebelum sesi ada, jadi kiriman pertama tidak punya
  /// konteks user.
  String? _lastRegistrationId;

  /// `true` setelah listener di [attach] terpasang. Mencegah [syncDeviceToBackend]
  /// berjalan sebelum ada yang menerima hasil registrasi.
  bool _listenersReady = false;

  /// Inisialisasi Firebase. Mengembalikan `false` bila `google-services.json`
  /// belum dipasang, supaya aplikasi tetap bisa dijalankan tanpa crash.
  static Future<bool> ensureFirebase() async {
    try {
      await Firebase.initializeApp();
      return true;
    } on Object {
      return false;
    }
  }

  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> attach({required void Function(String route) go}) async {
    if (_attached) return;
    _attached = true;
    _go = go;

    await _initLocalNotifications();
    await _handleLocalLaunch();
    await requestPermission();

    if (!_firebaseReady) {
      _set(
        lastSync: 'FCM nonaktif: android/app/google-services.json belum ada',
      );
      return;
    }

    // firebase_messaging 17 mengganti `getToken`/`onTokenRefresh` dengan
    // `register()`/`onRegistered`. Nilai yang diterima adalah Firebase
    // Installation ID, yaitu target kirim langsung untuk instance aplikasi ini.
    // Listener ini wajib ada: tanpa itu backend menyimpan ID basi dan push
    // berhenti diam-diam setelah reinstall atau clear data.
    _subscriptions.add(
      FirebaseMessaging.instance.onRegistered.listen(_sendTokenToBackend),
    );

    // Foreground: sistem tidak menampilkan banner, jadi tampilkan manual.
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen(_onForegroundMessage),
    );

    // Background lalu diklik: pesan dianggap terbaca.
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened),
    );

    await syncToken();
    await subscribeToTopic();
    _listenersReady = true;
    await handleTerminatedMessage();
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _status.dispose();
  }

  Future<bool> requestPermission() async {
    try {
      if (_firebaseReady) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          announcement: false,
          carPlay: false,
          criticalAlert: false,
        );
        final granted =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
        _set(permissionGranted: granted);
        return granted;
      }

      final android = _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission() ?? false;
      _set(permissionGranted: granted);
      return granted;
    } on Object {
      _set(permissionGranted: false);
      return false;
    }
  }

  /// Memicu registrasi FCM lalu menunggu Firebase Installation ID.
  ///
  /// Pengiriman ke backend dilakukan oleh listener permanen di [attach],
  /// jadi method ini hanya melengkapi nilai yang ditampilkan di halaman Debug.
  Future<String?> syncToken() async {
    if (!_firebaseReady) return null;

    final registration = Completer<String?>();
    late final StreamSubscription<String> subscription;
    subscription = FirebaseMessaging.instance.onRegistered.listen((id) {
      if (!registration.isCompleted) registration.complete(id);
    });

    try {
      await FirebaseMessaging.instance.register();
      return await registration.future.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      _set(
        lastSync: 'Belum ada Installation ID. Cek koneksi dan Play Services.',
      );
      return null;
    } on Object catch (error) {
      _set(lastSync: 'Gagal registrasi FCM: ${friendlyApiError(error)}');
      return null;
    } finally {
      await subscription.cancel();
    }
  }

  /// Mengirim ulang ID perangkat yang sudah diperoleh ke backend.
  ///
  /// Registrasi FCM berjalan di [attach], yaitu sebelum pengguna login. Kiriman
  /// pertama karena itu tidak punya konteks user, sehingga `POST /devices` tidak
  /// bisa menyimpannya per pengguna. Method ini dipanggil sekali setiap login
  /// berhasil. Bila ID belum pernah diterima, registrasi dicoba ulang — hasilnya
  /// tetap dikirim oleh listener `onRegistered` di [attach].
  Future<void> syncDeviceToBackend() async {
    if (!_firebaseReady || !_listenersReady) return;

    final id = _lastRegistrationId;
    if (id == null) {
      await syncToken();
      return;
    }
    await _sendTokenToBackend(id);
  }

  Future<void> subscribeToTopic() async {
    if (!_firebaseReady) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      _set(subscribedToTopic: true, lastSync: 'Berlangganan topik $topic');
    } on Object catch (error) {
      _set(lastSync: 'Gagal berlangganan topik: ${friendlyApiError(error)}');
    }
  }

  Future<void> unsubscribeFromTopic() async {
    if (!_firebaseReady) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      _set(subscribedToTopic: false, lastSync: 'Berhenti dari topik $topic');
    } on Object catch (error) {
      _set(lastSync: 'Gagal berhenti topik: ${friendlyApiError(error)}');
    }
  }

  /// Pesan dari notifikasi yang membuka aplikasi saat terminated.
  Future<void> handleTerminatedMessage() async {
    if (!_firebaseReady) return;
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        await _onMessageOpened(initial);
      }
    } on Object {
      // Tidak ada pesan awal: bukan error.
    }
  }

  /// Dipakai halaman Debug untuk membuktikan banner foreground dan deep link
  /// tanpa menunggu campaign FCM.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    required String route,
    String? inboxId,
  }) async {
    if (!_localReady) {
      await _initLocalNotifications();
    }

    // Jumlah notifikasi belum dibaca dipakai sebagai angka badge.
    final unread = await inbox?.all().then((items) => items.length) ?? 0;

    final android = AndroidNotificationDetails(
      _channelId,
      'Pengumuman Kampus',
      channelDescription: 'Notifikasi pengumuman dan jadwal kampus',
      importance: Importance.high,
      priority: Priority.high,
      // Badge di icon launcher. Banyak launcher (termasuk ColorOS) hanya
      // menampilkan titik, bukan angka; itu batasan sistem, bukan aplikasi.
      channelShowBadge: true,
      number: unread,
    );
    final details = NotificationDetails(
      android: android,
      iOS: const DarwinNotificationDetails(),
    );

    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: details,
      payload: NotificationPayload.encode(route: route, inboxId: inboxId),
    );
  }

  /// Meniru pesan FCM yang masuk: menyimpan ke kotak masuk lalu menampilkan
  /// banner. Dipakai halaman Debug supaya demo kotak masuk bisa dilakukan tanpa
  /// menunggu campaign dari Firebase Console.
  Future<void> simulateIncomingMessage({
    required String title,
    required String body,
    required String route,
  }) async {
    final item = inboxItemFromPayload(
      messageId: 'sim-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      data: <String, dynamic>{'route': route},
      receivedAt: DateTime.now(),
    );

    if (item != null) {
      await inbox?.add(item);
      onInboxChanged?.call();
    }

    await showLocalNotification(
      title: title,
      body: body,
      route: route,
      inboxId: item?.id,
    );
  }

  /// Menyimpan notifikasi ke kotak masuk lalu menampilkan banner.
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Pengumuman kampus';
    final body = message.notification?.body ?? '';
    final route = routeFromMessage(message.data);

    final item = inboxItemFromPayload(
      messageId: message.messageId,
      title: title,
      body: body,
      data: message.data,
      receivedAt: DateTime.now(),
    );

    if (item != null) {
      await inbox?.add(item);
      onInboxChanged?.call();
    }

    await showLocalNotification(
      title: title,
      body: body,
      route: route,
      inboxId: item?.id,
    );
  }

  /// Notifikasi diketuk dari tray: item dianggap terbaca lalu dihapus.
  Future<void> _onMessageOpened(RemoteMessage message) async {
    final item = inboxItemFromPayload(
      messageId: message.messageId,
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
      receivedAt: DateTime.now(),
    );

    if (item != null) {
      await inbox?.remove(item.id);
      onInboxChanged?.call();
    }

    _go?.call(routeFromMessage(message.data));
  }

  Future<void> _sendTokenToBackend(String token) async {
    _lastRegistrationId = token;
    _set(tokenPreview: maskToken(token), tokenUpdatedAt: DateTime.now());
    try {
      await _dio.post<dynamic>(
        ApiConfig.devicesPath,
        data: <String, dynamic>{
          'fcm_token': token,
          'platform': defaultTargetPlatform == TargetPlatform.android
              ? 'android'
              : 'ios',
        },
      );
      _set(lastSync: 'Token terkirim ke POST ${ApiConfig.devicesPath}');
    } on Object catch (error) {
      _set(lastSync: 'Gagal kirim token: ${friendlyApiError(error)}');
    }
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Izin iOS diminta lewat FirebaseMessaging.requestPermission, bukan di sini,
    // supaya tidak muncul dua dialog berurutan.
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    try {
      await _local.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: _onLocalNotificationTapped,
      );
      _localReady = true;
      await _ensureChannel();
    } on Object {
      _localReady = false;
    }
  }

  /// Banner lokal diketuk: item dianggap terbaca, lalu halaman tujuan dibuka.
  Future<void> _onLocalNotificationTapped(NotificationResponse response) async {
    final payload = NotificationPayload.decode(response.payload);

    if (payload.inboxId != null) {
      await inbox?.remove(payload.inboxId!);
      onInboxChanged?.call();
    }

    _go?.call(payload.route);
  }

  /// Android 8+ membuang notifikasi yang channel-nya belum ada.
  ///
  /// Channel ini juga yang dirujuk `default_notification_channel_id` di
  /// AndroidManifest, sehingga banner FCM saat background/terminated punya
  /// tujuan yang valid meski aplikasi belum pernah menampilkan banner lokal.
  Future<void> _ensureChannel() async {
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        'Pengumuman Kampus',
        description: 'Notifikasi pengumuman dan jadwal kampus',
        importance: Importance.high,
        // Menampilkan titik/angka di icon launcher.
        showBadge: true,
      ),
    );
  }

  /// Aplikasi dibuka dari notifikasi lokal (foreground -> terminated).
  Future<void> _handleLocalLaunch() async {
    try {
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        final response = launch?.notificationResponse;
        if (response != null) {
          await _onLocalNotificationTapped(response);
        }
      }
    } on Object {
      // Plugin belum siap (mis. hot reload setelah menambah dependency).
    }
  }

  void _set({
    bool? permissionGranted,
    String? tokenPreview,
    DateTime? tokenUpdatedAt,
    String? lastSync,
    bool? subscribedToTopic,
  }) {
    _status.value = _status.value.copyWith(
      permissionGranted: permissionGranted,
      tokenPreview: tokenPreview,
      tokenUpdatedAt: tokenUpdatedAt,
      lastSync: lastSync,
      subscribedToTopic: subscribedToTopic,
    );
  }
}
