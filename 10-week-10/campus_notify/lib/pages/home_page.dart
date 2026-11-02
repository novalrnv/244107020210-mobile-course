import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../messaging/push_service.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/inbox_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final announcements = ref.watch(announcementRepositoryProvider).all();
    final theme = Theme.of(context);

    if (auth.isLoading && !auth.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () => context.push(AppRoutes.inbox),
            icon: Badge.count(
              count: ref.watch(unreadCountProvider),
              isLabelVisible: ref.watch(unreadCountProvider) > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Debug notifikasi',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => context.push(AppRoutes.debug),
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NotificationCard(
            onTap: () => context.push(AppRoutes.debug),
          ),
          const SizedBox(height: 20),
          Text('Pengumuman terbaru', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final item in announcements)
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(item.date),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push(AppRoutes.announcement(item.id)),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Klik notifikasi akan membuka halaman detail pengumuman sesuai '
            'nilai data.route dari backend.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(pushServiceProvider);
    final theme = Theme.of(context);

    return ValueListenableBuilder<PushStatus>(
      valueListenable: service.status,
      builder: (context, status, _) {
        final active = status.firebaseReady && status.permissionGranted;
        return Card(
          color: active
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    active
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active ? 'Notifikasi aktif' : 'Notifikasi belum aktif',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          active
                              ? 'Topik ${PushService.topic}'
                              : 'Buka halaman debug untuk mengaktifkan',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
