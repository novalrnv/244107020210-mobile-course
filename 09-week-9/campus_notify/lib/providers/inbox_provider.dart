import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/inbox_item.dart';
import '../notifications/inbox_store.dart';

final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => InboxRepository(),
);

/// Sumber kebenaran isi kotak masuk untuk seluruh UI.
///
/// Membaca ulang dari penyimpanan setiap kali [refresh] dipanggil, karena
/// notifikasi baru bisa ditulis oleh isolate background FCM yang tidak punya
/// akses ke Riverpod.
final inboxProvider = AsyncNotifierProvider<InboxNotifier, List<InboxItem>>(
  InboxNotifier.new,
);

class InboxNotifier extends AsyncNotifier<List<InboxItem>> {
  @override
  Future<List<InboxItem>> build() {
    return ref.watch(inboxRepositoryProvider).all();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(inboxRepositoryProvider).all(),
    );
  }

  /// Dipanggil saat pengguna membaca notifikasi: item hilang dari daftar.
  Future<void> markRead(String id) async {
    final items = await ref.read(inboxRepositoryProvider).remove(id);
    state = AsyncData(items);
  }

  Future<void> clearAll() async {
    final items = await ref.read(inboxRepositoryProvider).clear();
    state = AsyncData(items);
  }
}

/// Jumlah notifikasi belum dibaca. Karena item yang dibaca langsung dihapus,
/// nilai ini sama dengan panjang daftar.
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(inboxProvider).value?.length ?? 0;
});
