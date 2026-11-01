import 'package:campus_notify/messaging/push_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('maskToken', () {
    test('hanya menyisakan 12 karakter pertama', () {
      expect(maskToken('abcdefghijklmnopqrstuvwxyz'), 'abcdefghijkl...');
    });

    test('ID pendek tidak tampil utuh', () {
      expect(maskToken('abc'), isNot(contains('abc')));
      expect(maskToken('abc').endsWith('...'), isTrue);
    });
  });

  group('PushService tanpa Firebase', () {
    test('syncDeviceToBackend tidak mengirim apa pun', () async {
      final service = PushService(httpClient: Dio(), firebaseReady: false);
      addTearDown(service.dispose);

      await service.syncDeviceToBackend();

      expect(service.status.value.tokenPreview, isNull);
    });

    test('syncToken mengembalikan null tanpa menyentuh jaringan', () async {
      final service = PushService(httpClient: Dio(), firebaseReady: false);
      addTearDown(service.dispose);

      expect(await service.syncToken(), isNull);
    });
  });
}
