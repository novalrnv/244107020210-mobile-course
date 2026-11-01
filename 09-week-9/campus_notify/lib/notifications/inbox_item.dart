/// Satu notifikasi yang tersimpan di kotak masuk aplikasi.
///
/// `read` tidak disimpan sebagai kolom terpisah: notifikasi yang sudah dibaca
/// langsung dihapus dari daftar, sesuai perilaku yang diminta tugas. Dengan
/// begitu jumlah item selalu sama dengan jumlah notifikasi belum dibaca.
class InboxItem {
  const InboxItem({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    required this.receivedAt,
  });

  final String id;
  final String title;
  final String body;

  /// Path internal yang dibuka saat item diketuk.
  final String route;

  final DateTime receivedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'body': body,
    'route': route,
    'receivedAt': receivedAt.toIso8601String(),
  };

  /// Mengembalikan `null` untuk data rusak, supaya satu baris cacat tidak
  /// membuat seluruh kotak masuk gagal dibaca.
  static InboxItem? fromJson(Object? raw) {
    if (raw is! Map) return null;

    final id = raw['id'];
    final title = raw['title'];
    final receivedAt = DateTime.tryParse(raw['receivedAt']?.toString() ?? '');

    if (id is! String || id.isEmpty || title is! String || receivedAt == null) {
      return null;
    }

    return InboxItem(
      id: id,
      title: title,
      body: raw['body']?.toString() ?? '',
      route: raw['route']?.toString() ?? '',
      receivedAt: receivedAt,
    );
  }
}
