import 'package:prak1/prak1.dart' as prak1;

void main(List<String> arguments) {
  print('Hello world: ${prak1.calculate()}!');
  var name = 'noval';
  var umur = 20;
  var alamat = 'jl.Kembang Kertas';
  var tinggi = '165';
  var iseng = umur + int.parse(tinggi);
  print('alamat $alamat');
  print('nama $name');
  print('umur $umur');
  print(iseng);
}
