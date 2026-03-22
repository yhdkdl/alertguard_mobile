import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'alert_history_model.dart';

class AlertHistoryRepository {
  final Dio _dio = DioClient.instance;

  Future<List<AlertHistoryModel>> getAlertHistory() async {
    final response = await _dio.get('/alerts/history/');
    return (response.data as List)
        .map((json) => AlertHistoryModel.fromJson(json))
        .toList();
  }
}
