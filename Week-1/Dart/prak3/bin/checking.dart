import 'package:prak3/prak3.dart' as prak3;

import 'dart:io';

void main(List<String> arguments) {
  int a = 10;
  int b = 20;
  print(a == b);
  print(identical(a, b));

  String nama1 = 'Novalidi';
  String nama2 = 'novalidi';
  print(nama1 == nama2);
  print(identical(nama1, nama2));
}
