import 'package:campus_notify/notifications/inbox_item.dart';
import 'package:campus_notify/notifications/inbox_store.dart';
import 'package:campus_notify/providers/inbox_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

InboxItem _item(String id) {
  return InboxItem(
    id: id,
    title: 'Judul $id',
    body: 'Isi $id',
    route: '/pengumuman/$id',
    receivedAt: DateTime(2026, 11, 2, 10, 0),
  );
}

void main() {
  late InMemoryInboxStorage storage;
  late ProviderContainer container;

  setUp(() {
    storage = InMemoryInboxStorage();
    container = ProviderContainer.test(
      overrides: [
        inboxRepositoryProvider.overrideWithValue(
          InboxRepository(storage: storage),
        ),
      ],
    );
  });

  test('kotak masuk kosong saat pertama dibuka', () async {
    expect(await container.read(inboxProvider.future), isEmpty);
    expect(container.read(unreadCountProvider), 0);
  });

  test('membaca notifikasi mengurangi jumlah belum dibaca', () async {
    storage.items = <InboxItem>[_item('1'), _item('2')];
    await container.read(inboxProvider.future);

    expect(container.read(unreadCountProvider), 2);

    await container.read(inboxProvider.notifier).markRead('1');

    expect(container.read(unreadCountProvider), 1);
    expect(
      container.read(inboxProvider).value?.map((item) => item.id),
      <String>['2'],
    );
  });

  test('refresh membaca notifikasi baru dari penyimpanan', () async {
    await container.read(inboxProvider.future);
    expect(container.read(unreadCountProvider), 0);

    // Meniru isolate background yang menulis langsung ke penyimpanan.
    storage.items = <InboxItem>[_item('9')];
    await container.read(inboxProvider.notifier).refresh();

    expect(container.read(unreadCountProvider), 1);
  });

  test('hapus semua mengosongkan kotak masuk', () async {
    storage.items = <InboxItem>[_item('1'), _item('2')];
    await container.read(inboxProvider.future);

    await container.read(inboxProvider.notifier).clearAll();

    expect(container.read(unreadCountProvider), 0);
  });
}
