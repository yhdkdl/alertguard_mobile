import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';

class AuthRepository {
  final Dio _dio = DioClient.instance;

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
    final response = await _dio.post(
      '/auth/login/',
      data: {'email': email, 'password': password},
    );

    await SecureStorage.saveTokens(
      accessToken: response.data['access'],
      refreshToken: response.data['refresh'],
    );
  }

  Future<void> logout() async {
    await SecureStorage.clearTokens();
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getAccessToken();
    return token != null;
  }
}
