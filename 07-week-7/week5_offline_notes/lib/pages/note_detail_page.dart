import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../providers/note_providers.dart';
import '../widgets/note_form_dialog.dart';

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.id});

  final int id;

  Future<void> _editNote(BuildContext context, WidgetRef ref, Note note) async {
    final result = await showDialog<NoteFormResult>(
      context: context,
      builder: (_) => NoteFormDialog(initial: note),
    );
    if (result == null) return;
    await ref.read(noteActionsProvider).update(
          note.copyWith(title: result.title, body: result.body),
        );
  }

  Future<void> _deleteNote(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(noteActionsProvider).delete(id);
      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteByIdProvider(id));

    return noteAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Detail Catatan')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Detail Catatan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e', textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (note) {
        if (note == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Catatan')),
            body: const Center(
              child: Text(
                'Catatan tidak ditemukan',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Catatan'),
            actions: [
              IconButton(
                tooltip: 'Ubah',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editNote(context, ref, note),
              ),
              IconButton(
                tooltip: 'Hapus',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteNote(context, ref),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                note.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    avatar: Icon(
                      note.dirty ? Icons.cloud_off : Icons.cloud_done,
                      size: 16,
                      color: note.dirty ? Colors.orange.shade800 : Colors.green.shade800,
                    ),
                    label: Text(
                      note.dirty ? 'Belum tersinkron' : 'Tersinkron',
                      style: TextStyle(
                        fontSize: 12,
                        color: note.dirty ? Colors.orange.shade900 : Colors.green.shade900,
                      ),
                    ),
                    backgroundColor: note.dirty ? Colors.orange.shade50 : Colors.green.shade50,
                    side: BorderSide(
                      color: note.dirty ? Colors.orange.shade200 : Colors.green.shade200,
                    ),
                  ),
                  Text(
                    'Diperbarui: ${note.updatedAt.toLocal().toString().split('.').first}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                note.body.isEmpty ? '(Tidak ada isi catatan)' : note.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: note.body.isEmpty ? Colors.grey : null,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
