import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class DioClient {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.6:8000/api/v1',
  );

  static const _defaultTimeout = Duration(seconds: 15);
  static const _uploadTimeout = Duration(seconds: 60);

  static Dio get instance {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _defaultTimeout,
        receiveTimeout: _defaultTimeout,
        sendTimeout: _defaultTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(_AuthInterceptor());
    return dio;
  }

  static Dio get uploadInstance {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _defaultTimeout,
        receiveTimeout: _uploadTimeout,
        sendTimeout: _uploadTimeout,
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
    final data = err.response?.data;
    String message = 'Something went wrong';

    if (data is Map) {
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
