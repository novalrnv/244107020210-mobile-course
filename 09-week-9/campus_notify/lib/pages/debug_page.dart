import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../messaging/push_service.dart';
import '../providers/app_providers.dart';
import '../routes.dart';

/// Halaman bukti untuk laporan: status izin, token terpotong, status topik,
/// dan tombol untuk memicu banner lokal tanpa menunggu campaign FCM.
class DebugPage extends ConsumerWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(pushServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Debug notifikasi')),
      body: ValueListenableBuilder<PushStatus>(
        valueListenable: service.status,
        builder: (context, status, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: status.firebaseReady
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.firebaseReady
                            ? 'Firebase aktif'
                            : 'Firebase belum dikonfigurasi',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        status.firebaseReady
                            ? 'FCM siap menerima pesan.'
                            : 'Letakkan google-services.json di android/app/ '
                                  'lalu jalankan ulang aplikasi. Tanpa itu '
                                  'aplikasi tetap jalan, FCM dimatikan.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Row(
                label: 'Izin notifikasi',
                value: status.permissionGranted ? 'Diberikan' : 'Belum',
              ),
              _Row(
                label: 'Firebase Installation ID',
                value: status.tokenPreview ?? 'Belum ada',
                monospace: true,
              ),
              _Row(
                label: 'ID diperbarui',
                value: _formatTime(status.tokenUpdatedAt),
              ),
              _Row(
                label: 'Topik ${PushService.topic}',
                value: status.subscribedToTopic ? 'Berlangganan' : 'Tidak',
              ),
              _Row(
                label: 'Endpoint backend',
                value: 'POST ${ApiConfig.devicesPath}',
                monospace: true,
              ),
              _Row(
                label: 'Sinkronisasi terakhir',
                value: status.lastSync ?? '-',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final granted = await service.requestPermission();
                      if (!context.mounted) return;
                      _toast(
                        context,
                        granted
                            ? 'Izin notifikasi diberikan'
                            : 'Izin notifikasi belum diberikan',
                      );
                    },
                    icon: const Icon(Icons.notifications_outlined),
                    label: const Text('Minta izin'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final id = await service.syncToken();
                      if (!context.mounted) return;
                      _toast(
                        context,
                        id == null
                            ? 'Installation ID belum tersedia. Cek Play Services.'
                            : 'ID ${maskToken(id)} dikirim ke backend',
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Registrasi FCM'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      if (status.subscribedToTopic) {
                        await service.unsubscribeFromTopic();
                      } else {
                        await service.subscribeToTopic();
                      }
                      if (!context.mounted) return;
                      _toast(context, 'Status topik diperbarui');
                    },
                    icon: const Icon(Icons.campaign_outlined),
                    label: Text(
                      status.subscribedToTopic ? 'Berhenti topik' : 'Langganan',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Uji banner & deep link', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Kirim notifikasi lokal, tekan Home, lalu klik bannernya. '
                'Aplikasi harus terbuka di ${AppRoutes.announcement('3')}.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => service.showLocalNotification(
                  title: 'Jadwal kuliah berubah',
                  body: 'Kelas Mobile pindah ke Ruang A2 jam 13.00',
                  route: AppRoutes.announcement('3'),
                ),
                icon: const Icon(Icons.send_outlined),
                label: const Text('Kirim notifikasi uji'),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Token/ID di halaman ini dipotong menjadi 12 karakter '
                          'pertama. Nilai penuh tidak pernah ditulis ke log '
                          'atau ditampilkan di layar.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatTime(DateTime? value) {
    if (value == null) return '-';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: monospace
                  ? theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    )
                  : theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
