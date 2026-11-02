import 'package:dio/dio.dart';

import 'api_client.dart';

class AuthSession {
  const AuthSession({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

/// Error yang pesannya aman ditampilkan ke pengguna.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Autentikasi lewat API kampus (Laravel + Sanctum).
///
/// Memakai Dio sendiri, bukan `dioProvider`, karena klien itu memasang
/// interceptor yang menempelkan token dan mencoba refresh saat 401. Memakainya
/// di sini akan membuat login yang gagal memicu refresh, lalu gagal lagi —
/// lingkaran yang tidak pernah selesai.
class AuthRepository {
  AuthRepository({Dio? client}) : _client = client ?? _buildClient();

  final Dio _client;

  static Dio _buildClient() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
        // Laravel butuh header ini agar menjawab JSON, bukan redirect HTML.
        headers: <String, dynamic>{'Accept': Headers.jsonContentType},
      ),
    );
  }

  /// Menukar email dan kata sandi dengan token Sanctum.
  ///
  /// Sanctum tidak memisahkan access dan refresh token, jadi nilai yang sama
  /// disimpan di kedua slot. Dengan begitu `SessionKeeper` dan interceptor 401
  /// yang sudah ada tetap bekerja tanpa perubahan.
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/login',
      data: <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final token = _tokenFrom(response.data);
    return AuthSession(access: token, refresh: token);
  }

  /// Menukar token lama dengan token baru. Token lama dihapus server.
  Future<String> refresh(String refreshToken) async {
    if (refreshToken.isEmpty) {
      throw const AuthException('Refresh token hilang');
    }

    final response = await _client.post<Map<String, dynamic>>(
      '/refresh',
      options: Options(headers: <String, dynamic>{
        'Authorization': 'Bearer $refreshToken',
      }),
    );

    return _tokenFrom(response.data);
  }

  /// Mencabut token di server. Dipanggil sebelum token lokal dihapus.
  Future<void> logout(String token) async {
    await _client.post<Map<String, dynamic>>(
      '/logout',
      options: Options(headers: <String, dynamic>{
        'Authorization': 'Bearer $token',
      }),
    );
  }

  String _tokenFrom(Map<String, dynamic>? body) {
    final data = body?['data'];
    final token = data is Map ? data['token'] : null;

    if (token is! String || token.isEmpty) {
      throw const AuthException('Respons server tidak berisi token.');
    }
    return token;
  }
}
