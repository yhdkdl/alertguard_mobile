import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class DioClient {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.6:8000/api/v1',
  );
  // 10.0.2.2 is how Android emulator reaches your Mac/PC localhost
  // For physical device: use your computer's local IP e.g. http://192.168.1.5:8000/api/v1

  static Dio get instance {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
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
    // Skip adding token for auth endpoints
    final isAuthRoute = options.path.contains('/auth/');
    if (!isAuthRoute) {
      final token = await SecureStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Surface a clean error message from Django's response
    final data = err.response?.data;
    String message = 'Something went wrong';

    if (data is Map) {
      // Django returns errors as {"field": ["message"]} or {"detail": "message"}
      final values = data.values.first;
      if (values is List && values.isNotEmpty) {
        message = values.first.toString();
      } else if (values is String) {
        message = values;
      }
    }

    err = err.copyWith(message: message);
    handler.next(err);
  }
}
