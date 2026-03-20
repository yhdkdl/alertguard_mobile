import 'package:dio/dio.dart';
import '../network/dio_client.dart';

class AlertService {
  final Dio _dio = DioClient.instance;

  Future<bool> sendAlert({
    required String triggerType,
    double? latitude,
    double? longitude,
    bool isTest = false,
  }) async {
    try {
      final formData = FormData.fromMap({
        'trigger_type': triggerType,
        'is_test': isTest.toString(),
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      });

      final response = await _dio.post(
        '/alerts/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('[AlertService] Failed to send alert: $e');
      return false;
    }
  }
}

final alertServiceInstance = AlertService();
