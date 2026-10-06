import 'package:flutter/material.dart';
 
import '../data/local/note.dart';
 
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });
 
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
 
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        note.dirty ? Icons.cloud_off : Icons.cloud_done,
        color: note.dirty ? Colors.orange : Colors.green,
      ),
      title: Row(
        children: [
          Expanded(child: Text(note.title)),
          if (note.dirty) ...[
            const SizedBox(width: 8),
            Chip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              label: const Text(
                'belum tersinkron',
                style: TextStyle(fontSize: 11),
              ),
              backgroundColor: Colors.orange.shade100,
              side: BorderSide(color: Colors.orange.shade300),
            ),
          ],
        ],
      ),
      subtitle: Text(
        note.body.isEmpty ? '(tanpa isi)' : note.body,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
      trailing: IconButton(
        tooltip: 'Hapus',
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}
