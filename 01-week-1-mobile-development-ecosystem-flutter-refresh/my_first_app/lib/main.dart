import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profil Mahasiswa')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.audiotrack, size: 72),
              SizedBox(height: 16),
              Text('Justin Bieber', style: TextStyle(fontSize: 24)),
              Text('Sorry', style: TextStyle(fontSize: 20)),
              Text(
                'Teknik Informatika | Politeknik Negeri Malang',
                style: TextStyle(fontSize: 18),
              ),
              Text('Pemrograman Mobile | Flutter'),
            ],
          ),
        ),
      ),
    );
  }
}
