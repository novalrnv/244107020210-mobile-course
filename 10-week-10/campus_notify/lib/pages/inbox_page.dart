import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../notifications/inbox_item.dart';
import '../providers/inbox_provider.dart';

/// Daftar notifikasi yang masuk. Item yang dibaca langsung hilang, sesuai
/// perilaku yang diminta tugas: membuka notifikasi berarti menandainya terbaca.
class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          inbox.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () =>
                        ref.read(inboxProvider.notifier).clearAll(),
                    child: const Text('Hapus semua'),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: inbox.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Gagal memuat notifikasi: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mark_email_read_outlined,
                      size: 56,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada notifikasi',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Notifikasi yang sudah dibaca akan hilang dari daftar.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return Dismissible(
                key: ValueKey<String>(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: theme.colorScheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                onDismissed: (_) =>
                    ref.read(inboxProvider.notifier).markRead(item.id),
                child: _InboxTile(item: item),
              );
            },
          );
        },
      ),
    );
  }
}

class _InboxTile extends ConsumerWidget {
  const _InboxTile({required this.item});

  final InboxItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.notifications_active_outlined,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.body.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 4),
          Text(
            formatReceivedAt(item.receivedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      isThreeLine: item.body.isNotEmpty,
      onTap: () async {
        // Dibaca berarti hilang dari daftar, jadi dihapus lebih dulu.
        await ref.read(inboxProvider.notifier).markRead(item.id);
        if (!context.mounted) return;
        if (item.route.isEmpty) return;
        context.push(item.route);
      },
    );
  }
}

/// Waktu terima dalam bentuk yang mudah dibaca saat presentasi.
String formatReceivedAt(DateTime value, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(value);

  if (difference.inMinutes < 1) return 'Baru saja';
  if (difference.inMinutes < 60) return '${difference.inMinutes} menit lalu';
  if (difference.inHours < 24) return '${difference.inHours} jam lalu';
  if (difference.inDays < 7) return '${difference.inDays} hari lalu';

  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
