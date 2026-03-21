import 'dart:io';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../network/dio_client.dart';
import 'location_service.dart';
import 'camera_service.dart';

class AlertService {
  final Dio _dio = DioClient.instance;

  Future<bool> sendAlert({
    required String triggerType,
    bool isTest = false,
  }) async {
    try {
      print('[AlertService] Starting alert capture...');

      // Run GPS and camera capture in parallel for speed
      final results = await Future.wait([
        LocationService.getCurrentLocation(),
        CameraService.captureAlertPhotos(),
      ]);

      final position = results[0] as Position?; // Position? from GPS
      final photos = results[1] as Map<String, File?>;

      print('[AlertService] GPS: $position');
      print(
        '[AlertService] Photos: front=${photos['front']?.path}, rear=${photos['rear']?.path}',
      );

      // Build multipart form data
      final formFields = <String, dynamic>{
        'trigger_type': triggerType,
        'is_test': isTest.toString(),
      };

      // Add GPS if available
      if (position != null) {
        formFields['latitude'] = position.latitude.toString();
        formFields['longitude'] = position.longitude.toString();
      } else {
        print('[AlertService] No GPS fix available; sending alert without coordinates.');
      }

      // Add photos if available
      if (photos['front'] != null) {
        formFields['front_photo'] = await MultipartFile.fromFile(
          photos['front']!.path,
          filename: 'front_photo.jpg',
        );
      }

      if (photos['rear'] != null) {
        formFields['rear_photo'] = await MultipartFile.fromFile(
          photos['rear']!.path,
          filename: 'rear_photo.jpg',
        );
      }

      final response = await _dio.post(
        '/alerts/',
        data: FormData.fromMap(formFields),
        options: Options(contentType: 'multipart/form-data'),
      );

      // Clean up temp photo files after upload
      _cleanupPhotos(photos);

      print('[AlertService] Alert sent. Status: ${response.data['status']}');
      return response.statusCode == 201;
    } catch (e) {
      print('[AlertService] Failed to send alert: $e');
      return false;
    }
  }

  void _cleanupPhotos(Map<String, File?> photos) {
    for (final file in photos.values) {
      try {
        file?.deleteSync();
      } catch (_) {}
    }
  }
}

final alertServiceInstance = AlertService();
