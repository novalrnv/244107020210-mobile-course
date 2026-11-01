import 'package:campus_notify/notifications/message_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final receivedAt = DateTime(2026, 11, 2, 10, 0);

  test('judul dan isi diambil dari blok notification', () {
    final item = inboxItemFromPayload(
      messageId: 'msg-1',
      title: 'Jadwal berubah',
      body: 'Kelas pindah ke A2',
      data: <String, dynamic>{'route': '/pengumuman/3'},
      receivedAt: receivedAt,
    );

    expect(item, isNotNull);
    expect(item!.id, 'msg-1');
    expect(item.title, 'Jadwal berubah');
    expect(item.body, 'Kelas pindah ke A2');
    expect(item.route, '/pengumuman/3');
  });

  test('pesan data-only memakai judul dari data', () {
    final item = inboxItemFromPayload(
      messageId: 'msg-2',
      title: null,
      body: null,
      data: <String, dynamic>{
        'title': 'Pengumuman baru',
        'body': 'Isi dari data',
        'route': 'pengumuman/5',
      },
      receivedAt: receivedAt,
    );

    expect(item?.title, 'Pengumuman baru');
    expect(item?.body, 'Isi dari data');
    expect(item?.route, '/pengumuman/5');
  });

  test('pesan tanpa judul tidak masuk kotak masuk', () {
    final item = inboxItemFromPayload(
      messageId: 'msg-3',
      title: '   ',
      body: 'tanpa judul',
      data: const <String, dynamic>{},
      receivedAt: receivedAt,
    );

    expect(item, isNull);
  });

  test('route kosong jatuh ke beranda', () {
    final item = inboxItemFromPayload(
      messageId: 'msg-4',
      title: 'Judul',
      body: 'Isi',
      data: const <String, dynamic>{},
      receivedAt: receivedAt,
    );

    expect(item?.route, '/');
  });

  test('tanpa messageId, id cadangan stabil untuk isi yang sama', () {
    final first = inboxItemFromPayload(
      messageId: null,
      title: 'Judul',
      body: 'Isi',
      data: <String, dynamic>{'route': '/pengumuman/1'},
      receivedAt: receivedAt,
    );
    final second = inboxItemFromPayload(
      messageId: null,
      title: 'Judul',
      body: 'Isi',
      data: <String, dynamic>{'route': '/pengumuman/1'},
      receivedAt: receivedAt.add(const Duration(minutes: 5)),
    );

    expect(first?.id, isNotEmpty);
    expect(first?.id, second?.id);
  });

  test('isi berbeda menghasilkan id cadangan berbeda', () {
    final first = inboxItemFromPayload(
      messageId: null,
      title: 'Judul A',
      body: 'Isi',
      data: const <String, dynamic>{},
      receivedAt: receivedAt,
    );
    final second = inboxItemFromPayload(
      messageId: null,
      title: 'Judul B',
      body: 'Isi',
      data: const <String, dynamic>{},
      receivedAt: receivedAt,
    );

    expect(first?.id, isNot(second?.id));
  });
}
