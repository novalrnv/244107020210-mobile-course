import 'package:campus_notify/pages/inbox_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 2, 12, 0);

  test('kurang dari semenit ditulis baru saja', () {
    expect(
      formatReceivedAt(now.subtract(const Duration(seconds: 20)), now: now),
      'Baru saja',
    );
  });

  test('hitungan menit dan jam', () {
    expect(
      formatReceivedAt(now.subtract(const Duration(minutes: 5)), now: now),
      '5 menit lalu',
    );
    expect(
      formatReceivedAt(now.subtract(const Duration(hours: 3)), now: now),
      '3 jam lalu',
    );
    expect(
      formatReceivedAt(now.subtract(const Duration(days: 2)), now: now),
      '2 hari lalu',
    );
  });

  test('lebih dari sepekan memakai tanggal', () {
    expect(
      formatReceivedAt(DateTime(2026, 10, 20, 9, 0), now: now),
      '20 Okt 2026',
    );
  });
}
