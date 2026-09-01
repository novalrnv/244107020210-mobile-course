void main() {
  double luas = hitungLuasPersegiPanjang(10, 10);
  print('luas persegi panjang : $luas');

  Profil profil1 = Profil(nama: 'Khoirul Umam Novalidi', nim: '244107020210');
  String emailDitampilkan = profil1.email ?? 'Belum ada email';
  print('Nama ${profil1.nama}, Nim ${profil1.nim}, Email : $emailDitampilkan');
}

double hitungLuasPersegiPanjang(double panjang, double lebar) {
  return panjang * lebar;
}

class Profil {
  Profil({required this.nama, required this.nim, this.email});
  final String nama;
  final String nim;
  final String? email;
}
