import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
 
import '../data/local/note.dart';
import '../providers/note_providers.dart';
import '../widgets/note_form_dialog.dart';
import 'settings_page.dart';
 
class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});
 
  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, [
    Note? note,
  ]) async {
    final result = await showDialog<NoteFormResult>(
      context: context,
      builder: (_) => NoteFormDialog(initial: note),
    );
    if (result == null) return; // dibatalkan
    final actions = ref.read(noteActionsProvider);
    if (note == null) {
      await actions.add(result.title, result.body);
    } else {
      await actions.update(
        note.copyWith(title: result.title, body: result.body),
      );
    }
  }
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirty = ref.watch(dirtyCountProvider).value ?? 0;
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          Tooltip(
            message: 'Catatan belum tersinkron',
            child: Badge(
              isLabelVisible: dirty > 0,
              label: Text('$dirty'),
              child: const Icon(Icons.cloud_upload_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: 'Gagal membaca database: $e',
          onRetry: () => ref.invalidate(notesProvider),
        ),
        data: (notes) {
          if (notes.isEmpty) return const _EmptyView();
          return ListView.separated(
            itemCount: notes.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                leading: Icon(
                  note.dirty ? Icons.cloud_off : Icons.cloud_done,
                  color: note.dirty ? Colors.orange : Colors.green,
                ),
                title: Text(note.title),
                subtitle: Text(
                  note.body.isEmpty ? '(tanpa isi)' : note.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _openForm(context, ref, note),
                trailing: IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      ref.read(noteActionsProvider).delete(note.id!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Catatan'),
      ),
    );
  }
}
 
class _EmptyView extends StatelessWidget {
  const _EmptyView();
 
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_alt_outlined, size: 64),
          SizedBox(height: 12),
          Text('Belum ada catatan. Tekan + untuk menambah.'),
        ],
      ),
    );
  }
}
 
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
 
  final String message;
  final VoidCallback onRetry;
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
