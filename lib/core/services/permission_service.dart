import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';

class PermissionService {
  /// Request all permissions the app needs upfront.
  /// Called once on home screen first load.
  static Future<void> requestAllPermissions() async {
    await _requestLocationPermission();
    await _requestCameraPermission();
  }

  static Future<void> _requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (e) {
      print('[Permissions] Location request failed: $e');
    }
  }

  static Future<void> _requestCameraPermission() async {
    try {
      // Initializing a camera triggers the system permission dialog
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.dispose();
    } catch (e) {
      // Permission denied — that is okay, we handle it gracefully later
      print('[Permissions] Camera request failed: $e');
    }
  }
}
