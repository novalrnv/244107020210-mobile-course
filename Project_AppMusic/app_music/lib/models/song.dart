// Model Song: merepresentasikan satu lagu dalam aplikasi
class Song {
  String title;    // Judul lagu
  String artist;   // Nama artis
  String album;    // Nama album
  String image;    // Path gambar cover (di assets/images/)
  String audio;    // Path file audio (di assets/audio/)
  bool isFavorite; // Status favorit, default false

  Song({
    required this.title,
    required this.artist,
    required this.album,
    required this.image,
    required this.audio,
    this.isFavorite = false,
  });
}

// Data dummy: daftar lagu yang digunakan di seluruh aplikasi
final List<Song> dummySongs = [
  Song(
    title: 'Night Drive',
    artist: 'Nova',
    album: 'Midnight',
    image: 'assets/images/cover1.jpg',
    audio: 'assets/audio/song1.mp3',
  ),
  Song(
    title: 'Summer',
    artist: 'Aria',
    album: 'Golden Hour',
    image: 'assets/images/cover2.jpg',
    audio: 'assets/audio/song2.mp3',
  ),
  Song(
    title: 'Lost Again',
    artist: 'Raka',
    album: 'Echoes',
    image: 'assets/images/cover3.jpg',
    audio: 'assets/audio/song3.mp3',
  ),
  Song(
    title: 'Morning Light',
    artist: 'Naya',
    album: 'Sunrise',
    image: 'assets/images/cover4.jpg',
    audio: 'assets/audio/song4.mp3',
  ),
  Song(
    title: 'Dreaming',
    artist: 'Reno',
    album: 'Clouds',
    image: 'assets/images/cover5.jpg',
    audio: 'assets/audio/song5.mp3',
  ),
  Song(
    title: 'Memories',
    artist: 'Alva',
    album: 'Retrospect',
    image: 'assets/images/cover6.jpg',
    audio: 'assets/audio/song6.mp3',
  ),
];
