import 'package:flutter/material.dart';
import 'package:app_music/models/song.dart';
import 'package:app_music/pages/player_page.dart';

// Widget SongList: menampilkan satu lagu dalam format baris list (ListTile)
// Digunakan di halaman Search dan Library
class SongList extends StatelessWidget {
  final Song song;
  final List<Song> allSongs;
  final int index;
  final VoidCallback? onFavoriteTap; // Callback saat tombol favorit ditekan

  const SongList({
    super.key,
    required this.song,
    required this.allSongs,
    required this.index,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // Cover album kecil di kiri
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          song.image,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.music_note,
              color: Color(0xFF3D8EF0),
              size: 24,
            ),
          ),
        ),
      ),
      // Judul lagu
      title: Text(
        song.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Artis - album
      subtitle: Text(
        '${song.artist} • ${song.album}',
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 12,
        ),
      ),
      // Tombol favorit di kanan
      trailing: IconButton(
        onPressed: onFavoriteTap,
        icon: Icon(
          song.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: song.isFavorite ? const Color(0xFF3D8EF0) : const Color(0xFF9E9E9E),
          size: 20,
        ),
      ),
      // Ketuk baris untuk membuka Player
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerPage(
              songs: allSongs,
              initialIndex: index,
            ),
          ),
        );
      },
    );
  }
}
