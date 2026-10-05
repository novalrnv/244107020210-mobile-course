import 'package:flutter/material.dart';
import 'package:app_music/models/song.dart';
import 'package:app_music/widgets/song_card.dart';
import 'package:app_music/widgets/song_list.dart';

// Halaman Home: menampilkan greeting, recently played, dan recommended songs
class HomePage extends StatefulWidget {
  final List<Song> songs; // Daftar lagu dari parent (main.dart)

  const HomePage({super.key, required this.songs});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Index lagu "Recently Played" (3 lagu pertama)
  List<Song> get _recentSongs => widget.songs.take(3).toList();

  // Index lagu "Recommended" (3 lagu terakhir)
  List<Song> get _recommendedSongs => widget.songs.skip(3).toList();

  // Toggle favorit dari list, update langsung via setState
  void _toggleFavorite(int index) {
    setState(() {
      widget.songs[index].isFavorite = !widget.songs[index].isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: greeting dan avatar
              _buildHeader(),

              const SizedBox(height: 24),

              // Section Recently Played
              _buildSectionTitle('Recently Played'),
              const SizedBox(height: 12),
              _buildRecentlyPlayed(),

              const SizedBox(height: 28),

              // Section Recommended Songs (format list)
              _buildSectionTitle('Recommended Songs'),
              const SizedBox(height: 8),
              _buildRecommendedList(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Header dengan greeting dan nama pengguna
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome ',
                style: TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Noval',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Avatar pengguna (initial-based placeholder, R-23)
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF3D8EF0),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'N',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Label judul section
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Horizontal scroll untuk Recently Played menggunakan SongCard
  Widget _buildRecentlyPlayed() {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _recentSongs.length,
        itemBuilder: (context, index) {
          return SongCard(
            song: _recentSongs[index],
            allSongs: widget.songs,
            index: index, // index di allSongs (0, 1, 2)
          );
        },
      ),
    );
  }

  // List vertikal untuk Recommended Songs menggunakan SongList
  Widget _buildRecommendedList() {
    return ListView.builder(
      // Nonaktifkan scroll pada ListView karena sudah dibungkus SingleChildScrollView
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recommendedSongs.length,
      itemBuilder: (context, index) {
        // Index di allSongs dimulai dari 3 (skip(3))
        final songIndex = index + 3;
        return SongList(
          song: widget.songs[songIndex],
          allSongs: widget.songs,
          index: songIndex,
          onFavoriteTap: () => _toggleFavorite(songIndex),
        );
      },
    );
  }
}
