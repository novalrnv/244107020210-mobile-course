import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/note_provider.dart';
import '../providers/theme_provider.dart';
import '../models/note.dart';
import 'note_form_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _dirtyCount = 0;

  @override
  void initState() {
    super.initState();
    _updateDirtyCount();
  }

  Future<void> _updateDirtyCount() async {
    final notifier = ref.read(noteListProvider.notifier);
    final count = await notifier.getDirtyCount();
    if (mounted) {
      setState(() {
        _dirtyCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteState = ref.watch(noteListProvider);
    final isDarkMode = ref.watch(themeProvider);
    final lastOpened = ref.watch(lastOpenedProvider);

    // Update dirty count ketika noteState berubah
    ref.listen(noteListProvider, (prev, next) {
      _updateDirtyCount();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          // Badge dirty count
          if (_dirtyCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Badge(
                label: Text('$_dirtyCount'),
                child: IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync catatan',
                  onPressed: () => _syncNotes(context),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync catatan',
              onPressed: () => _syncNotes(context),
            ),
          // Toggle tema
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDarkMode ? 'Mode terang' : 'Mode gelap',
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Info waktu terakhir dibuka
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDarkMode ? Colors.grey[800] : Colors.blue[50],
            child: Text(
              'Terakhir dibuka: $lastOpened',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
          ),
          // Daftar catatan
          Expanded(
            child: noteState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(noteListProvider.notifier).loadNotes();
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
              data: (notes) {
                if (notes.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_add, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada catatan.\nTekan + untuk menambah.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(noteListProvider.notifier).loadNotes();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      return _buildNoteCard(notes[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NoteFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                note.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Badge dirty
            if (note.isDirty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Belum sync',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              note.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Diperbarui: ${dateFormatter.format(note.updatedAt)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteFormScreen(note: note),
            ),
          );
        },
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(note),
        ),
      ),
    );
  }

  void _confirmDelete(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: Text('Yakin ingin menghapus "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(noteListProvider.notifier).deleteNote(note.id!);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncNotes(BuildContext context) async {
    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final count = await ref.read(noteListProvider.notifier).syncNotes();

    if (mounted) {
      Navigator.pop(context); // tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? '$count catatan berhasil di-sync!'
                : 'Semua catatan sudah ter-sync.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
