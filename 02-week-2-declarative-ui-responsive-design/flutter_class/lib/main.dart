import 'package:flutter/material.dart';
import 'package:flutter_class/lirik.dart';
import 'mahasiswa.dart';

void main() {
  runApp(const Novalidi());
}

class Novalidi extends StatefulWidget {
  const Novalidi({super.key});

  @override
  State<Novalidi> createState() => _NovalidiState();
}

class _NovalidiState extends State<Novalidi> {
  double _sliderValue = 30.0;

  @override
  Widget build(BuildContext context) {
    final mhs = Mahasiswa(nama: 'Nopal', umur: 20, kelas: 'TI 3C');
    final lagu = Lirik(
      judul: 'Lesung Pipi',
      artis: 'Raim Laode',
      lirik1: 'Tatkala mentari \nTerbenam di ufuk barat \nDisaat itulah \nDingin rindu selimuti \nKeindahan senyuman dari \nLesung pipi itu \nMenikmati imaji bersamamu',
      lirik2: 'Maka terimalah diriku \nKita akan bahagia selamanya \nKuberjanji jadi suamimu \nDan ku akan memberikan yang terbaik \nUntukmu',
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: Scaffold(
        appBar: AppBar(title: const Text('Music App')),
        body: Column(
          children: [
            Center(child: Text(lagu.judul, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Center(child: Text('Artis : ${lagu.artis}', style: const TextStyle(fontSize: 15))),
            Align(alignment: Alignment.centerLeft, child: Text(lagu.lirik1)),
            Align(alignment: Alignment.centerRight, child: Text('\n${lagu.lirik2}')),
            Slider(
              value: _sliderValue,
              min: 0.0,
              max: 100.0,
              onChanged: (value) {
                setState(() {
                  _sliderValue = value;
                });
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.red,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.skip_previous, color: Colors.white), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.pause, color: Colors.white), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.skip_next, color: Colors.white), label: ''),
          ],
        ),
      ),
    );
  }
}