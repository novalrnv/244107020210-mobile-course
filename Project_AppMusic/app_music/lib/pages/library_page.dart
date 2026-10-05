import 'package:flutter/material.dart';
import 'package:app_music/models/song.dart';
import 'package:app_music/widgets/song_list.dart';

// Halaman Library: menampilkan Favorites, Playlist, dan Recently Played
class LibraryPage extends StatefulWidget {
  final List<Song> songs;

  const LibraryPage({super.key, required this.songs});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  // Ambil lagu yang sudah difavoritkan
  List<Song> get _favoriteSongs =>
      widget.songs.where((s) => s.isFavorite).toList();

  // Recently Played: 3 lagu pertama (simulasi data lokal)
  List<Song> get _recentSongs => widget.songs.take(3).toList();

  void _toggleFavorite(Song song) {
    setState(() {
      song.isFavorite = !song.isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        title: const Text(
          'Library',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Section: Favorite Songs
          _buildSectionHeader(Icons.favorite, 'Favorite Songs', const Color(0xFF3D8EF0)),
          _buildFavoriteSection(),

          const SizedBox(height: 8),

          // Section: My Playlist (statis, simulasi)
          _buildSectionHeader(Icons.playlist_play, 'My Playlist', const Color(0xFF6C4ADB)),
          _buildPlaylistSection(),

          const SizedBox(height: 8),

          // Section: Recently Played
          _buildSectionHeader(Icons.history, 'Recently Played', const Color(0xFF4ADBAC)),
          _buildRecentSection(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Header tiap section dengan ikon dan warna aksen
  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Daftar lagu favorit
  Widget _buildFavoriteSection() {
    if (_favoriteSongs.isEmpty) {
      // Empty state: belum ada favorit
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.favorite_border, color: Color(0xFF9E9E9E), size: 20),
            SizedBox(width: 12),
            Text(
              'Belum ada lagu favorit.\nTambahkan dari halaman Player.',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _favoriteSongs.length,
      itemBuilder: (context, index) {
        final song = _favoriteSongs[index];
        final originalIndex = widget.songs.indexOf(song);
        return SongList(
          song: song,
          allSongs: widget.songs,
          index: originalIndex,
          onFavoriteTap: () => _toggleFavorite(song),
        );
      },
    );
  }

  // Playlist statis (simulasi, tidak perlu backend)
  Widget _buildPlaylistSection() {
    final List<String> playlists = [
      'Playlist Belajar',
      'Musik Santai',
      'Top Picks',
    ];

    return Column(
      children: playlists.map((name) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.queue_music, color: Color(0xFF6C4ADB), size: 24),
          ),
          title: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle: const Text(
            '0 lagu',
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
        );
      }).toList(),
    );
  }

  // 3 lagu terakhir yang diputar
  Widget _buildRecentSection() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentSongs.length,
      itemBuilder: (context, index) {
        return SongList(
          song: _recentSongs[index],
          allSongs: widget.songs,
          index: index,
          onFavoriteTap: () => _toggleFavorite(_recentSongs[index]),
        );
      },
    );
  }
}
