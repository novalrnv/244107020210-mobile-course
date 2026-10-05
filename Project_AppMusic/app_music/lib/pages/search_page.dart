import 'package:flutter/material.dart';
import 'package:app_music/models/song.dart';
import 'package:app_music/widgets/song_list.dart';

// Halaman Search: pencarian lagu dan tampilan kategori genre
class SearchPage extends StatefulWidget {
  final List<Song> songs;

  const SearchPage({super.key, required this.songs});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _searchResults = []; // Hasil pencarian
  bool _isSearching = false;      // Apakah pengguna sedang mengetik?

  // Daftar kategori genre dengan warna berbeda
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Pop', 'color': const Color(0xFF3D8EF0)},
    {'name': 'Rock', 'color': const Color(0xFF6C4ADB)},
    {'name': 'Hip Hop', 'color': const Color(0xFFDB4A6C)},
    {'name': 'Chill', 'color': const Color(0xFF4ADBAC)},
    {'name': 'R&B', 'color': const Color(0xFFDB9C4A)},
    {'name': 'Electronic', 'color': const Color(0xFF4AAEDE)},
  ];

  // Fungsi pencarian: filter lagu berdasarkan judul atau artis
  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    final results = widget.songs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase()) ||
          song.artist.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _isSearching = true;
      _searchResults = results;
    });
  }

  void _toggleFavorite(int index) {
    setState(() {
      widget.songs[index].isFavorite = !widget.songs[index].isFavorite;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          _buildSearchBar(),

          const SizedBox(height: 16),

          // Tampilkan kategori atau hasil pencarian
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildCategories(),
          ),
        ],
      ),
    );
  }

  // Search bar dengan ikon kaca pembesar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Cari lagu atau artis...',
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF9E9E9E)),
          // Tampilkan tombol X jika ada teks di search bar
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF9E9E9E)),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1E1E2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3D8EF0), width: 1.5),
          ),
        ),
      ),
    );
  }

  // Grid 2 kolom untuk kategori genre
  Widget _buildCategories() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Browse Categories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,       // 2 kolom
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,  // Lebar:Tinggi card
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryCard(_categories[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Card untuk satu kategori genre
  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Container(
      decoration: BoxDecoration(
        color: (category['color'] as Color).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (category['color'] as Color).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          category['name'],
          style: TextStyle(
            color: category['color'],
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Hasil pencarian dalam format list
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      // Empty state: tidak ada hasil
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: Color(0xFF9E9E9E), size: 64),
            SizedBox(height: 12),
            Text(
              'Lagu tidak ditemukan',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final song = _searchResults[index];
        // Cari index asli di widget.songs untuk toggle favorit yang benar
        final originalIndex = widget.songs.indexOf(song);
        return SongList(
          song: song,
          allSongs: widget.songs,
          index: originalIndex,
          onFavoriteTap: () => _toggleFavorite(originalIndex),
        );
      },
    );
  }
}
