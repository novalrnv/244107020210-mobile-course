import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Provider untuk tema gelap/terang
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false) {
    _loadTheme();
  }

  // Baca tema dari SharedPreferences saat pertama kali
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('isDarkMode') ?? false;
  }

  // Toggle antara gelap dan terang
  Future<void> toggleTheme() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', state);
  }
}

// Provider untuk waktu terakhir dibuka
final lastOpenedProvider =
    StateNotifierProvider<LastOpenedNotifier, String>((ref) {
  return LastOpenedNotifier();
});

class LastOpenedNotifier extends StateNotifier<String> {
  LastOpenedNotifier() : super('Belum pernah dibuka') {
    _loadAndUpdate();
  }

  Future<void> _loadAndUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpened = prefs.getString('lastOpened');

    if (lastOpened != null) {
      final dateTime = DateTime.parse(lastOpened);
      final formatter = DateFormat('dd MMM yyyy, HH:mm');
      state = formatter.format(dateTime);
    }

    // Simpan waktu sekarang sebagai waktu terakhir dibuka
    await prefs.setString('lastOpened', DateTime.now().toIso8601String());
  }
}
