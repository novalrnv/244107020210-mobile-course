import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:app_music/models/song.dart';

// Halaman Player: menampilkan pemutar musik utama
// Menerima daftar lagu dan index lagu yang sedang diputar
class PlayerPage extends StatefulWidget {
  final List<Song> songs;
  final int initialIndex;

  const PlayerPage({
    super.key,
    required this.songs,
    required this.initialIndex,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late AudioPlayer _audioPlayer; // Objek pemutar audio dari just_audio
  late int _currentIndex;        // Index lagu yang sedang aktif
  bool _isPlaying = false;       // Status play/pause
  Duration _duration = Duration.zero;   // Total durasi lagu
  Duration _position = Duration.zero;   // Posisi saat ini

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _audioPlayer = AudioPlayer();
    _loadSong(); // Muat lagu pertama saat halaman dibuka

    // Dengarkan perubahan durasi total lagu
    _audioPlayer.durationStream.listen((d) {
      if (d != null && mounted) {
        setState(() => _duration = d);
      }
    });

    // Dengarkan perubahan posisi (progress) lagu
    _audioPlayer.positionStream.listen((p) {
      if (mounted) {
        setState(() => _position = p);
      }
    });

    // Dengarkan status pemutaran (playing/paused)
    _audioPlayer.playingStream.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });

    // Ketika lagu selesai, otomatis pindah ke lagu berikutnya
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _nextSong();
      }
    });
  }

  // Memuat dan memutar lagu berdasarkan _currentIndex
  Future<void> _loadSong() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAsset(_currentSong.audio);
      await _audioPlayer.play();
    } catch (e) {
      // Jika file audio tidak ditemukan, tampilkan snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File audio tidak ditemukan: ${_currentSong.audio}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // Getter untuk lagu yang sedang aktif
  Song get _currentSong => widget.songs[_currentIndex];

  // Toggle play/pause
  void _togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  // Pindah ke lagu berikutnya
  void _nextSong() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.songs.length;
      _position = Duration.zero;
    });
    _loadSong();
  }

  // Pindah ke lagu sebelumnya
  void _previousSong() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + widget.songs.length) % widget.songs.length;
      _position = Duration.zero;
    });
    _loadSong();
  }

  // Toggle status favorit pada lagu saat ini
  void _toggleFavorite() {
    setState(() {
      _currentSong.isFavorite = !_currentSong.isFavorite;
    });
  }

  // Mengubah Duration menjadi format mm:ss
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Selalu dispose AudioPlayer agar tidak memory leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A), // Background sangat gelap
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Now Playing',
          style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1),
        ),
        centerTitle: true,
        actions: [
          // Tombol favorit di kanan atas
          IconButton(
            icon: Icon(
              _currentSong.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _currentSong.isFavorite ? const Color(0xFF3D8EF0) : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        // SingleChildScrollView mencegah overflow di layar kecil
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Cover album besar
            _buildAlbumCover(),

            const SizedBox(height: 24),

            // Judul lagu dan artis
            _buildSongInfo(),

            const SizedBox(height: 20),

            // Progress bar dan durasi
            _buildProgressBar(),

            const SizedBox(height: 20),

            // Tombol kontrol: previous, play/pause, next
            _buildControls(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Cover album dengan ukuran responsif berdasarkan tinggi layar
  Widget _buildAlbumCover() {
    // Ambil ukuran layar agar cover tidak overflow di HP kecil
    final screenHeight = MediaQuery.of(context).size.height;
    // Gunakan 35% dari tinggi layar, minimal 180, maksimal 260
    final coverSize = (screenHeight * 0.35).clamp(180.0, 260.0);

    return Center(
      child: Container(
        width: coverSize,
        height: coverSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Shadow biru sebagai focal point (R-12: shadow hanya pada elemen utama)
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3D8EF0).withValues(alpha: 0.3),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            _currentSong.image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              color: const Color(0xFF1E1E2E),
              child: const Icon(
                Icons.music_note,
                color: Color(0xFF3D8EF0),
                size: 80,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Judul lagu dan artis
  Widget _buildSongInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentSong.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _currentSong.artist,
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        // Tombol favorit di samping info lagu
        GestureDetector(
          onTap: _toggleFavorite,
          child: Icon(
            _currentSong.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _currentSong.isFavorite ? const Color(0xFF3D8EF0) : const Color(0xFF9E9E9E),
            size: 26,
          ),
        ),
      ],
    );
  }

  // Slider progress dan teks durasi
  Widget _buildProgressBar() {
    // Hitung nilai slider, jaga agar tidak melebihi durasi total
    final double sliderValue = (_duration.inSeconds > 0)
        ? _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble())
        : 0.0;

    return Column(
      children: [
        // Slider warna biru
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF3D8EF0),
            inactiveTrackColor: const Color(0xFF2A2A3E),
            thumbColor: const Color(0xFF3D8EF0),
            overlayColor: const Color(0xFF3D8EF0).withValues(alpha: 0.2),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: sliderValue,
            min: 0,
            max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1,
            onChanged: (value) {
              // Seek ke posisi yang dipilih
              _audioPlayer.seek(Duration(seconds: value.toInt()));
            },
          ),
        ),
        // Teks waktu: posisi saat ini dan total durasi
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
              ),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Baris tombol kontrol: previous, play/pause, next
  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tombol Previous
        IconButton(
          onPressed: _previousSong,
          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
        ),

        const SizedBox(width: 16),

        // Tombol Play/Pause (utama, berwarna biru)
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFF3D8EF0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Tombol Next
        IconButton(
          onPressed: _nextSong,
          icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
        ),
      ],
    );
  }
}
