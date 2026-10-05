import 'package:flutter/material.dart';
import 'package:app_music/models/song.dart';
import 'package:app_music/pages/home_page.dart';
import 'package:app_music/pages/search_page.dart';
import 'package:app_music/pages/library_page.dart';

void main() {
  runApp(const NovaMusicApp());
}

// Root aplikasi
class NovaMusicApp extends StatelessWidget {
  const NovaMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOVA MUSIC',
      debugShowCheckedModeBanner: false,
      // Tema dark mode dengan aksen biru
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3D8EF0),   // Biru sebagai warna utama
          surface: Color(0xFF1E1E2E),
        ),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

// MainShell: wrapper dengan BottomNavigationBar
// Semua halaman dibuat di sini agar daftar lagu (songs) bisa dibagikan ke semua halaman
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0; // Index tab yang sedang aktif

  // Satu daftar lagu dibagikan ke semua halaman agar favorit sinkron
  final List<Song> _songs = dummySongs;

  // Halaman yang tersedia sesuai tab
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(songs: _songs),
      SearchPage(songs: _songs),
      LibraryPage(songs: _songs),
    ];
  }

  // Dipanggil ketika tab di bottom nav ditekan
  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Rebuild pages agar status favorit terupdate di semua halaman
      _pages[0] = HomePage(songs: _songs);
      _pages[1] = SearchPage(songs: _songs);
      _pages[2] = LibraryPage(songs: _songs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack menjaga state tiap halaman (scroll position, dll.)
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Bottom Navigation Bar dengan 3 tab
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onTabTapped,
      backgroundColor: const Color(0xFF12121F), // Sedikit lebih gelap dari background
      selectedItemColor: const Color(0xFF3D8EF0),   // Biru untuk tab aktif
      unselectedItemColor: const Color(0xFF9E9E9E), // Abu untuk tab tidak aktif
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_music_outlined),
          activeIcon: Icon(Icons.library_music),
          label: 'Library',
        ),
      ],
    );
  }
}