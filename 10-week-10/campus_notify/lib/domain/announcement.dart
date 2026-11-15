/// Pengumuman kampus yang ditampilkan di halaman detail deep link.
///
/// Entitas murni: tanpa JSON, tanpa HTTP, tanpa Flutter. Cara memperoleh data
/// ada di lapisan `data/`, cara menampilkannya di `presentation/`.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.date,
    required this.body,
  });

  final String id;
  final String title;
  final String date;
  final String body;
}
