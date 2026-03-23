import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class DioClient {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://alertguard-api.onrender.com/api/v1',
  );
  // for local development
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.6:8000/api/v1

  static const _defaultTimeout = Duration(seconds: 15);
  static const _uploadTimeout = Duration(seconds: 60);

  // Cached instances — created once, reused everywhere
  static Dio? _instance;
  static Dio? _uploadInstance;

  static Dio get instance {
    _instance ??= _createDio(receiveTimeout: _defaultTimeout);
    return _instance!;
  }

  static Dio get uploadInstance {
    _uploadInstance ??= _createDio(receiveTimeout: _uploadTimeout);
    return _uploadInstance!;
  }

  static Dio _createDio({required Duration receiveTimeout}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _defaultTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(_AuthInterceptor());
    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isAuthRoute =
        options.path.contains('/auth/login') ||
        options.path.contains('/auth/register');

    if (!isAuthRoute) {
      final token = await SecureStorage.getAccessToken();
      print(
        '[DioClient] Path: ${options.path} | '
        'Token: ${token != null ? "present" : "MISSING"}',
      );
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Log the error
    print(
      '[DioClient] Error on ${err.requestOptions.path}: '
      '${err.response?.statusCode} ${err.response?.data}',
    );

    // Auto-refresh on 401
    if (err.response?.statusCode == 401) {
      final refreshToken = await SecureStorage.getRefreshToken();

      if (refreshToken != null) {
        try {
          print('[DioClient] Attempting token refresh...');

          // Use a plain Dio — no interceptors to avoid infinite loop
          final refreshDio = Dio(BaseOptions(baseUrl: DioClient.baseUrl));

          final response = await refreshDio.post(
            '/auth/token/refresh/',
            data: {'refresh': refreshToken},
          );

          final newAccessToken = response.data['access'];
          await SecureStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: refreshToken, // keep existing refresh token
          );

          print('[DioClient] Token refreshed successfully');

          // Retry the original request with new token
          err.requestOptions.headers['Authorization'] =
              'Bearer $newAccessToken';

          final retryResponse = await DioClient.instance.fetch(
            err.requestOptions,
          );
          return handler.resolve(retryResponse);
        } catch (e) {
          print('[DioClient] Token refresh failed: $e');
          // Refresh failed — clear tokens so user is sent to login
          await SecureStorage.clearTokens();
        }
      }
    }

    // Surface clean error message
    final data = err.response?.data;
    String message = 'Something went wrong';

    if (data is Map) {
      final first = data.values.isNotEmpty ? data.values.first : null;
      if (first is List && first.isNotEmpty) {
        message = first.first.toString();
      } else if (first is String) {
        message = first;
      } else if (data['detail'] is String) {
        message = data['detail'];
      }
    }

    err = err.copyWith(message: message);
    handler.next(err);
  }
}
