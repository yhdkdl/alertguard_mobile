import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';

class AuthRepository {
  final Dio _dio = DioClient.instance;

  static const _loginRetryDelay = Duration(seconds: 2);

  Future<void> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/register/',
      data: {'email': email, 'full_name': fullName, 'password': password},
    );

    await SecureStorage.saveTokens(
      accessToken: response.data['tokens']['access'],
      refreshToken: response.data['tokens']['refresh'],
    );
  }

  Future<void> login({required String email, required String password}) async {
    Response response;
    try {
      response = await _dio.post(
        '/auth/login/',
        data: {'email': email, 'password': password},
      );
    } on DioException catch (e) {
      if (!_isRetryableLoginError(e)) rethrow;

      // Backends on free tiers can be slow on first hit. Retry once.
      await Future<void>.delayed(_loginRetryDelay);
      response = await _dio.post(
        '/auth/login/',
        data: {'email': email, 'password': password},
      );
    }

    await SecureStorage.saveTokens(
      accessToken: response.data['access'],
      refreshToken: response.data['refresh'],
    );
  }

  bool _isRetryableLoginError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  Future<void> logout() async {
    await SecureStorage.clearTokens();
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getAccessToken();
    return token != null;
  }
}
