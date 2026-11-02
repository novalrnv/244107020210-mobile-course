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

/// Data contoh supaya halaman tujuan deep link punya isi tanpa backend.
/// Ganti dengan repository yang memanggil API kampus saat sudah tersedia.
class AnnouncementRepository {
  const AnnouncementRepository();

  static const _items = <Announcement>[
    Announcement(
      id: '1',
      title: 'Jadwal UTS semester ganjil',
      date: '20 Oktober 2026',
      body:
          'UTS dilaksanakan 27-31 Oktober 2026. Pastikan tidak ada tunggakan '
          'administrasi sebelum 25 Oktober agar bisa mengikuti ujian.',
    ),
    Announcement(
      id: '2',
      title: 'Pendaftaran UKM dibuka',
      date: '22 Oktober 2026',
      body:
          'Pendaftaran UKM gelombang kedua dibuka sampai 5 November 2026. '
          'Setiap mahasiswa boleh mendaftar maksimal dua UKM.',
    ),
    Announcement(
      id: '3',
      title: 'Jadwal kuliah berubah',
      date: '26 Oktober 2026',
      body:
          'Kelas Mobile Programming pindah ke Ruang A2, mulai pukul 13.00. '
          'Perubahan berlaku untuk seluruh kelas pagi dan sore.',
    ),
    Announcement(
      id: '4',
      title: 'Beasiswa prestasi akademik',
      date: '26 Oktober 2026',
      body:
          'Berkas beasiswa prestasi akademik dikumpulkan paling lambat '
          '10 November 2026 ke bagian kemahasiswaan.',
    ),
  ];

  List<Announcement> all() => List<Announcement>.unmodifiable(_items);

  Announcement? byId(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
