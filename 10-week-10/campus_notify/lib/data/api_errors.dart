import 'package:dio/dio.dart';

import 'auth_repository.dart';

/// Menerjemahkan error teknis menjadi kalimat yang bisa dibaca pengguna.
///
/// UI hanya boleh menerima string ini, bukan `DioException` mentah: pesan
/// seperti "DioExceptionType.connectionError" tidak berarti apa pun bagi
/// mahasiswa yang sedang buru-buru membuka pengumuman.
String friendlyApiError(Object error) {
  if (error is AuthException) return error.message;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Server terlalu lama merespons. Coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat server tidak valid.';
      case DioExceptionType.badResponse:
        return _fromStatusCode(error.response);
      case DioExceptionType.unknown:
        return 'Gagal menghubungi server. Coba lagi.';
    }
  }

  return 'Terjadi kesalahan. Coba lagi.';
}

String _fromStatusCode(Response<dynamic>? response) {
  final code = response?.statusCode;
  if (code == 401) return 'Sesi Anda berakhir. Silakan masuk kembali.';
  if (code == 403) return 'Anda tidak punya akses ke data ini.';
  if (code == 404) return 'Data yang diminta tidak ditemukan.';
  if (code != null && code >= 500) {
    return 'Server sedang bermasalah. Coba beberapa saat lagi.';
  }

  final message = _serverMessage(response?.data);
  return message ?? 'Permintaan ditolak (kode ${code ?? '-'}).';
}

/// Laravel mengirim `{"message": "..."}`; pakai itu bila ada.
String? _serverMessage(Object? body) {
  if (body is Map && body['message'] is String) {
    final message = (body['message'] as String).trim();
    if (message.isNotEmpty) return message;
  }
  return null;
}
