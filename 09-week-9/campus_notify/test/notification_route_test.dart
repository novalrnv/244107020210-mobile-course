import 'package:campus_notify/messaging/notification_route.dart';
import 'package:campus_notify/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('routeFromMessage', () {
    test('payload kosong jatuh ke beranda', () {
      expect(routeFromMessage(<String, dynamic>{}), AppRoutes.home);
      expect(routeFromMessage(<String, dynamic>{'route': ''}), AppRoutes.home);
      expect(
        routeFromMessage(<String, dynamic>{'route': '   '}),
        AppRoutes.home,
      );
    });

    test('route tanpa slash depan tetap dinormalkan', () {
      expect(
        routeFromMessage(<String, dynamic>{'route': 'pengumuman/3'}),
        '/pengumuman/3',
      );
      expect(
        routeFromMessage(<String, dynamic>{'route': '/pengumuman/3'}),
        '/pengumuman/3',
      );
    });

    test('tipe data selain string tidak dipaksa menjadi route', () {
      expect(
        routeFromMessage(<String, dynamic>{'route': 3}),
        AppRoutes.home,
      );
      expect(
        routeFromMessage(<String, dynamic>{'route': null}),
        AppRoutes.home,
      );
    });

    test('data payload gabungan membawa id pengumuman', () {
      const data = <String, dynamic>{
        'route': '/pengumuman/3',
        'id': '3',
        'title': 'Jadwal kuliah berubah',
      };
      expect(data['id'], '3');
      expect(routeFromMessage(data), AppRoutes.announcement('3'));
    });
  });

  test('normalizeRoute menerima payload notifikasi lokal', () {
    expect(normalizeRoute(null), AppRoutes.home);
    expect(normalizeRoute('debug'), AppRoutes.debug);
    expect(normalizeRoute(' /pengumuman/4 '), '/pengumuman/4');
  });

  group('NotificationPayload', () {
    test('membawa route dan id kotak masuk', () {
      final decoded = NotificationPayload.decode(
        NotificationPayload.encode(
          route: 'pengumuman/3',
          inboxId: 'msg-9',
        ),
      );

      expect(decoded.route, '/pengumuman/3');
      expect(decoded.inboxId, 'msg-9');
    });

    test('tanpa id kotak masuk tetap menghasilkan route valid', () {
      final decoded = NotificationPayload.decode(
        NotificationPayload.encode(route: '/debug'),
      );

      expect(decoded.route, '/debug');
      expect(decoded.inboxId, isNull);
    });

    test('payload lama berisi path saja tetap terbaca', () {
      final decoded = NotificationPayload.decode('pengumuman/7');

      expect(decoded.route, '/pengumuman/7');
      expect(decoded.inboxId, isNull);
    });

    test('payload null atau kosong jatuh ke beranda', () {
      expect(NotificationPayload.decode(null).route, AppRoutes.home);
      expect(NotificationPayload.decode('').route, AppRoutes.home);
    });
  });
}
