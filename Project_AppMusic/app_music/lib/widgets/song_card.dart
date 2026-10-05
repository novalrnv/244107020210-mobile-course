import 'package:flutter/material.dart';
import 'package:app_music/models/song.dart';
import 'package:app_music/pages/player_page.dart';

// Widget SongCard: menampilkan satu lagu dalam format card horizontal
// Digunakan di halaman Home pada section "Recently Played" dan "Recommended"
class SongCard extends StatelessWidget {
  final Song song;
  final List<Song> allSongs; // Daftar semua lagu untuk navigasi prev/next
  final int index;

  const SongCard({
    super.key,
    required this.song,
    required this.allSongs,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Ketuk card untuk membuka halaman Player
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
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E), // Dark card background
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover album
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                song.image,
                width: 160,
                height: 120,
                fit: BoxFit.cover,
                // Tampilkan placeholder jika gambar tidak ditemukan
                errorBuilder: (context, error, stack) => _buildPlaceholderCover(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul lagu
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Nama artis
                  Text(
                    song.artist,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Tombol play kecil di sudut kanan
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3D8EF0), // Biru accent
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder cover: ditampilkan saat file gambar belum ada
  Widget _buildPlaceholderCover() {
    return Container(
      width: 160,
      height: 120,
      color: const Color(0xFF2A2A3E),
      child: const Icon(
        Icons.music_note,
        color: Color(0xFF3D8EF0),
        size: 40,
      ),
    );
  }
}
