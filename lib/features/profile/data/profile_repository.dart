import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'profile_model.dart';

class ProfileRepository {
  final Dio _dio = DioClient.instance;

  Future<ProfileModel> getProfile() async {
    final response = await _dio.get('/auth/profile/');
    return ProfileModel.fromJson(response.data);
  }
}
