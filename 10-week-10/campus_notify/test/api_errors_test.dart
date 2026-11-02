import 'package:campus_notify/data/api_errors.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _error({
  DioExceptionType type = DioExceptionType.badResponse,
  int? statusCode,
  Object? data,
}) {
  final options = RequestOptions(path: '/pengumuman');
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: data,
          ),
  );
}

void main() {
  test('401 memberi pesan sesi berakhir', () {
    expect(
      friendlyApiError(_error(statusCode: 401)),
      'Sesi Anda berakhir. Silakan masuk kembali.',
    );
  });

  test('timeout dan offline dipisahkan', () {
    expect(
      friendlyApiError(_error(type: DioExceptionType.connectionTimeout)),
      contains('terlalu lama'),
    );
    expect(
      friendlyApiError(_error(type: DioExceptionType.connectionError)),
      contains('Tidak ada koneksi'),
    );
  });

  test('pesan validasi dari Laravel dipakai apa adanya', () {
    expect(
      friendlyApiError(
        _error(statusCode: 422, data: {'message': 'Email sudah terdaftar'}),
      ),
      'Email sudah terdaftar',
    );
  });

  test('5xx tidak membocorkan detail internal', () {
    expect(
      friendlyApiError(_error(statusCode: 500, data: 'stacktrace')),
      contains('Server sedang bermasalah'),
    );
  });

  test('AuthException tampil sebagai pesan ramah', () {
    expect(
      friendlyApiError(const AuthException('Email atau kata sandi tidak valid')),
      'Email atau kata sandi tidak valid',
    );
  });

  test('error tak dikenal tidak pernah kosong', () {
    expect(friendlyApiError(StateError('boom')), isNotEmpty);
  });
}
