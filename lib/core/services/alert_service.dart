import 'dart:io';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../network/dio_client.dart';
import 'location_service.dart';
import 'camera_service.dart';
import 'connectivity_service.dart';
import 'queue_service.dart';

enum AlertResult { sent, queued, failed }

enum _SendOutcome { sent, retryableFailure, nonRetryableFailure }

class AlertService {
  final Dio _dio = DioClient.uploadInstance;

  Future<AlertResult> sendAlert({
    required String triggerType,
    bool isTest = false,
  }) async {
    try {
      print('[AlertService] Starting alert capture...');

      // Step 1 — Capture GPS + photos in parallel
      final results = await Future.wait([
        LocationService.getCurrentLocation(),
        CameraService.captureAlertPhotos(),
      ]);

      final position = results[0] as Position?;
      final photos = results[1] as Map<String, File?>;
      final latitude = position?.latitude;
      final longitude = position?.longitude;
      final frontPhoto = photos['front'];
      final rearPhoto = photos['rear'];

      print('[AlertService] GPS: $position');
      print(
        '[AlertService] Photos: '
        'front=${frontPhoto?.path}, rear=${rearPhoto?.path}',
      );

      if (position == null) {
        print('[AlertService] No GPS fix — sending without coordinates');
      }

      // Step 2 — Generate idempotency key once
      // Same key reused on every retry — prevents duplicate alerts
      final idempotencyKey =
          'alert_${DateTime.now().millisecondsSinceEpoch}_$triggerType';

      // Step 3 — Check real internet connectivity
      final hasInternet = await ConnectivityService.hasInternet();

      if (!hasInternet) {
        print('[AlertService] No internet — queuing alert locally');
        await QueueService.enqueue(
          triggerType: triggerType,
          latitude: latitude,
          longitude: longitude,
          frontPhotoPath: frontPhoto?.path,
          rearPhotoPath: rearPhoto?.path,
          isTest: isTest,
          idempotencyKey: idempotencyKey,
        );
        return AlertResult.queued;
      }

      // Step 4 — Send immediately
      final sendOutcome = await _sendToBackend(
        triggerType: triggerType,
        latitude: latitude,
        longitude: longitude,
        frontPhoto: frontPhoto,
        rearPhoto: rearPhoto,
        isTest: isTest,
        idempotencyKey: idempotencyKey,
      );

      if (sendOutcome == _SendOutcome.sent) {
        _cleanupPhotos(photos);
        return AlertResult.sent;
      }

      if (sendOutcome == _SendOutcome.nonRetryableFailure) {
        print('[AlertService] Non-retryable backend rejection — not queuing');
        return AlertResult.failed;
      }

      // Step 5 — Send failed even with internet — queue for retry
      print('[AlertService] Send failed — queuing for retry');
      await QueueService.enqueue(
        triggerType: triggerType,
        latitude: latitude,
        longitude: longitude,
        frontPhotoPath: frontPhoto?.path,
        rearPhotoPath: rearPhoto?.path,
        isTest: isTest,
        idempotencyKey: idempotencyKey,
      );
      return AlertResult.queued;
    } catch (e) {
      print('[AlertService] Unexpected error: $e');
      return AlertResult.failed;
    }
  }

  /// Retry all pending alerts from the local queue.
  /// Called by QueueMonitor when connectivity is restored.
  Future<void> retryPendingAlerts() async {
    final pending = await QueueService.getPendingAlerts();

    print('[AlertService] Retrying ${pending.length} pending alerts...');

    if (pending.isEmpty) return;

    for (final alert in pending) {
      print('[AlertService] Attempting queued alert id: ${alert.id}');

      final sendOutcome = await _sendToBackend(
        triggerType: alert.triggerType,
        latitude: alert.latitude,
        longitude: alert.longitude,
        frontPhoto: QueueService.photoExists(alert.frontPhotoPath)
            ? File(alert.frontPhotoPath!)
            : null,
        rearPhoto: QueueService.photoExists(alert.rearPhotoPath)
            ? File(alert.rearPhotoPath!)
            : null,
        isTest: alert.isTest,
        idempotencyKey: alert.idempotencyKey,
      );

      if (sendOutcome == _SendOutcome.sent ||
          sendOutcome == _SendOutcome.nonRetryableFailure) {
        await QueueService.dequeue(alert.id!);
        print(
          '[AlertService] Queued alert ${alert.id} '
          '${sendOutcome == _SendOutcome.sent ? 'delivered' : 'dropped (non-retryable)'} and dequeued',
        );
      } else {
        await QueueService.incrementRetry(alert.id!);
        print(
          '[AlertService] Queued alert ${alert.id} '
          'retry failed — count incremented',
        );
      }
    }

    await QueueService.pruneExhausted();
  }

  Future<_SendOutcome> _sendToBackend({
    required String triggerType,
    double? latitude,
    double? longitude,
    File? frontPhoto,
    File? rearPhoto,
    bool isTest = false,
    String? idempotencyKey,
  }) async {
    try {
      final formFields = <String, dynamic>{
        'trigger_type': triggerType,
        'is_test': isTest.toString(),
        if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      };

      if (latitude != null) {
        formFields['latitude'] = latitude.toStringAsFixed(6);
      }
      if (longitude != null) {
        formFields['longitude'] = longitude.toStringAsFixed(6);
      }

      if (frontPhoto != null) {
        formFields['front_photo'] = await MultipartFile.fromFile(
          frontPhoto.path,
          filename: 'front_photo.jpg',
        );
      }

      if (rearPhoto != null) {
        formFields['rear_photo'] = await MultipartFile.fromFile(
          rearPhoto.path,
          filename: 'rear_photo.jpg',
        );
      }

      final response = await _dio.post(
        '/alerts/',
        data: FormData.fromMap(formFields),
        options: Options(contentType: 'multipart/form-data'),
      );

      print(
        '[AlertService] Backend response: '
        '${response.statusCode} ${response.data}',
      );

      // 201 = new alert created
      // 200 = idempotent match — already existed, no duplicate
      if (response.statusCode == 201 || response.statusCode == 200) {
        return _SendOutcome.sent;
      }

      // Unexpected non-exception status: retry for server-side transient issues.
      return _SendOutcome.retryableFailure;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      print(
        '[AlertService] Backend send failed: '
        'status=$statusCode data=$responseData message=${e.message}',
      );

      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        return _SendOutcome.nonRetryableFailure;
      }

      return _SendOutcome.retryableFailure;
    } catch (e) {
      print('[AlertService] Backend send failed: $e');
      return _SendOutcome.retryableFailure;
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
