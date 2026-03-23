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
  static const _authTimeout = Duration(seconds: 60);
  static const _uploadTimeout = Duration(seconds: 60);

  // Cached instances — created once, reused everywhere
  static Dio? _instance;
  static Dio? _authInstance;
  static Dio? _uploadInstance;

  static Dio get instance {
    _instance ??= _createDio(receiveTimeout: _defaultTimeout);
    return _instance!;
  }

  static Dio get authInstance {
    _authInstance ??= _createDio(receiveTimeout: _authTimeout);
    return _authInstance!;
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

  static Future<void> warmUpBackend() async {
    // Fire a lightweight request so sleeping backends can wake up early.
    final warmupDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );

    try {
      await warmupDio.get('/');
    } on DioException {
      // Any response (including 4xx/5xx) is enough for warm-up.
    } catch (_) {
      // Ignore non-network failures; warm-up is best-effort only.
    }
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

    // Connection/timeout cases usually indicate network instability
    // or a cold backend waking up.
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      message =
          'Server is taking longer than usual. Please wait a moment and try again.';
    }

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
