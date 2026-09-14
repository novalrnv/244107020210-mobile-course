class Mahasiswa {
  String nama;
  int umur;
  String kelas;

  Mahasiswa({required this.nama, required this.umur, required this.kelas});

  void tampilkanInfo() {
    print('Nama: $nama');
    print('Umur: $umur');
    print('Kelas: $kelas');
  }
}
