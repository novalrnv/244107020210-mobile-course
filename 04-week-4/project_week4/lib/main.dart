import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error mengambil kamera: ${e.description}');
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: MainScreen(cameras: cameras),
    ),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      TakePictureScreen(cameras: widget.cameras),
      const GpsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Kamera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'GPS',
          ),
        ],
      ),
    );
  }
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isNotEmpty) {
      _initCamera(_selectedCameraIndex);
    }
  }

  void _initCamera(int cameraIndex) {
    _controller = CameraController(
      widget.cameras[cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    setState(() {
      _isFlashOn = false;
      _initializeControllerFuture = _controller.initialize();
    });
  }

  void _toggleCamera() {
    if (widget.cameras.length > 1) {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
      _controller.dispose();
      _initCamera(_selectedCameraIndex);
    }
  }

  Future<void> _toggleFlash() async {
    try {
      await _initializeControllerFuture;
      if (_isFlashOn) {
        await _controller.setFlashMode(FlashMode.off);
        setState(() => _isFlashOn = false);
      } else {
        await _controller.setFlashMode(FlashMode.torch);
        setState(() => _isFlashOn = true);
      }
    } catch (e) {
      debugPrint('Error mengubah flash: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cameras.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ambil Foto')),
        body: const Center(child: Text('Tidak ada kamera yang ditemukan.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambil Foto'),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Flash',
            onPressed: _toggleFlash,
          ),
          if (widget.cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_android),
              tooltip: 'Ganti Kamera',
              onPressed: _toggleCamera,
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            if (!context.mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    DisplayPictureScreen(imagePath: image.path),
              ),
            );
          } catch (e) {
            debugPrint('Error mengambil foto: $e');
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Foto')),
      body: Column(
        children: [
          Expanded(child: Image.file(File(imagePath))),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Foto Ulang'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Foto berhasil disimpan!')),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan Foto'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<Placemark>> _getPlacemark(double lat, double lng) {
  return Geocoding().placemarkFromCoordinates(lat, lng);
}

class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  LatLng? _lokasi;
  String _alamat = 'Mencari alamat...';
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _ambilLokasi();
  }

  Future<void> _ambilLokasi() async {
    LocationPermission izin = await Geolocator.requestPermission();

    if (izin == LocationPermission.denied ||
        izin == LocationPermission.deniedForever) {
      return;
    }

    Position posisi = await Geolocator.getCurrentPosition();

    List<Placemark> placemark = await _getPlacemark(
      posisi.latitude,
      posisi.longitude,
    );

    setState(() {
      _lokasi = LatLng(posisi.latitude, posisi.longitude);
      _alamat =
          '${placemark[0].street}, ${placemark[0].subLocality}, ${placemark[0].locality}, ${placemark[0].country}';
    });

    _mapController.move(_lokasi!, 16);
  }

  @override
  Widget build(BuildContext context) {
    if (_lokasi == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('GPS Lokasi')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Mengambil lokasi...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('GPS Lokasi')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _lokasi!,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.project_week4',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _lokasi!,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _alamat,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mapController.move(_lokasi!, 16),
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
