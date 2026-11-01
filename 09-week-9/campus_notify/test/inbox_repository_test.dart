import 'package:campus_notify/notifications/inbox_item.dart';
import 'package:campus_notify/notifications/inbox_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

InboxItem _item(String id, {int minute = 0}) {
  return InboxItem(
    id: id,
    title: 'Judul $id',
    body: 'Isi $id',
    route: '/pengumuman/$id',
    receivedAt: DateTime(2026, 11, 2, 10, minute),
  );
}

void main() {
  late InMemoryInboxStorage storage;
  late InboxRepository repository;

  setUp(() {
    storage = InMemoryInboxStorage();
    repository = InboxRepository(storage: storage);
  });

  test('kotak masuk kosong saat pertama dibaca', () async {
    expect(await repository.all(), isEmpty);
  });

  test('notifikasi tersimpan dan terbaca kembali', () async {
    await repository.add(_item('1'));

    final items = await repository.all();

    expect(items, hasLength(1));
    expect(items.single.title, 'Judul 1');
    expect(items.single.route, '/pengumuman/1');
  });

  test('id yang sama tidak tersimpan dua kali', () async {
    await repository.add(_item('1'));
    await repository.add(_item('1'));

    expect(await repository.all(), hasLength(1));
  });

  test('notifikasi terbaru tampil paling atas', () async {
    await repository.add(_item('1', minute: 5));
    await repository.add(_item('2', minute: 30));

    final items = await repository.all();

    expect(items.map((item) => item.id), <String>['2', '1']);
  });

  test('membaca notifikasi menghapusnya dari daftar', () async {
    await repository.add(_item('1'));
    await repository.add(_item('2'));

    final items = await repository.remove('1');

    expect(items.map((item) => item.id), <String>['2']);
  });

  test('menghapus id yang tidak ada tidak mengubah penyimpanan', () async {
    await repository.add(_item('1'));
    final writesBefore = storage.writeCount;

    final items = await repository.remove('tidak-ada');

    expect(items, hasLength(1));
    expect(storage.writeCount, writesBefore);
  });

  test('hapus semua mengosongkan daftar', () async {
    await repository.add(_item('1'));
    await repository.add(_item('2'));

    expect(await repository.clear(), isEmpty);
    expect(await repository.all(), isEmpty);
  });

  test('item tanpa judul diabaikan saat dibaca dari penyimpanan', () {
    expect(InboxItem.fromJson(<String, dynamic>{'id': '1'}), isNull);
    expect(InboxItem.fromJson('bukan map'), isNull);
    expect(
      InboxItem.fromJson(<String, dynamic>{
        'id': '1',
        'title': 'Ada',
        'receivedAt': '2026-11-02T10:00:00.000',
      })?.title,
      'Ada',
    );
  });
}
