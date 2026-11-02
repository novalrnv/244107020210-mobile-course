import 'package:dio/dio.dart';

import 'session_keeper.dart';
import 'token_store.dart';

class ApiConfig {
  const ApiConfig._();

  /// Default mengarah ke server lokal lewat `adb reverse tcp:8000 tcp:8000`,
  /// sehingga HP bisa memakai `127.0.0.1` tanpa bergantung pada Wi-Fi kampus.
  /// Ganti lewat `--dart-define=CAMPUS_API_URL=http://<host>:8000/api`.
  static const baseUrl = String.fromEnvironment(
    'CAMPUS_API_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static const devicesPath = '/devices';
}

/// Dio dengan penempel access token + refresh otomatis sekali saat 401.
Dio buildApiClient({
  required TokenStore store,
  required SessionKeeper keeper,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      // Wajib: tanpa ini Laravel menjawab 401 dengan redirect ke route
      // `login` yang tidak ada di aplikasi API-only, sehingga yang sampai ke
      // pengguna adalah error 500, bukan pesan sesi berakhir.
      headers: <String, dynamic>{'Accept': Headers.jsonContentType},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null && access.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = error.requestOptions.extra[_retriedKey] == true;

        // Hanya 401 pertama yang memicu refresh. Tanpa penanda ini, retry
        // yang tetap 401 akan berputar tanpa henti.
        if (!isUnauthorized || alreadyRetried) {
          return handler.next(error);
        }

        final renewed = await keeper.renewAccess();
        if (renewed == null) {
          // Refresh ikut mati: biarkan error naik, guard route akan
          // mengarahkan pengguna ke /login.
          return handler.next(error);
        }

        try {
          final retryOptions = error.requestOptions
            ..headers['Authorization'] = 'Bearer $renewed'
            ..extra[_retriedKey] = true;
          final response = await dio.fetch<dynamic>(retryOptions);
          return handler.resolve(response);
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      },
    ),
  );

  return dio;
}

const _retriedKey = 'auth_retried';
