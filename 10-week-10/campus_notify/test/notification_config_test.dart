import 'dart:io';

import 'package:campus_notify/messaging/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Konfigurasi notifikasi tersebar di dua tempat: kode Dart dan
/// AndroidManifest. Kalau keduanya tidak sama, Android membuang notifikasi
/// FCM saat aplikasi di background tanpa pesan error. Tes ini menjaga
/// keduanya tetap sinkron.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');

  test('manifest tersedia', () {
    expect(manifest.existsSync(), isTrue);
  });

  test('channel default di manifest sama dengan channel di PushService', () {
    final content = manifest.readAsStringSync();
    final match = RegExp(
      r'default_notification_channel_id"\s+android:value="([^"]+)"',
    ).firstMatch(content);

    expect(match, isNotNull);
    expect(match!.group(1), PushService.channelId);
  });

  test('suara default di manifest sama dengan nama file suara', () {
    final content = manifest.readAsStringSync();
    final match = RegExp(
      r'default_notification_sound"\s+android:value="([^"]+)"',
    ).firstMatch(content);

    expect(match, isNotNull);
    expect(match!.group(1), PushService.soundName);
  });

  test('file suara ada di res/raw', () {
    final sound = File(
      'android/app/src/main/res/raw/${PushService.soundName}.wav',
    );

    expect(sound.existsSync(), isTrue);
    expect(sound.lengthSync(), greaterThan(1000));
  });
}
