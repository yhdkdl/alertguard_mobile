import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraService {
  /// Capture photos from both cameras.
  /// Returns a map with 'front' and 'rear' file paths.
  /// Either or both can be null if capture fails.
  static Future<Map<String, File?>> captureAlertPhotos() async {
    File? frontPhoto;
    File? rearPhoto;

    try {
      final cameras = await availableCameras();

      // Attempt rear camera first
      rearPhoto = await _captureFromCamera(
        cameras,
        CameraLensDirection.back,
        'rear',
      );

      // Then front camera
      frontPhoto = await _captureFromCamera(
        cameras,
        CameraLensDirection.front,
        'front',
      );
    } catch (e) {
      print('[Camera] Unexpected error: $e');
    }

    return {'front': frontPhoto, 'rear': rearPhoto};
  }

  static Future<File?> _captureFromCamera(
    List<CameraDescription> cameras,
    CameraLensDirection direction,
    String label,
  ) async {
    CameraController? controller;

    try {
      // Find camera with the requested direction
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == direction,
        orElse: () => throw Exception('$label camera not found'),
      );

      controller = CameraController(
        camera,
        ResolutionPreset.medium, // medium = good quality, smaller file size
        enableAudio: false, // no audio needed
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      // Small delay to let camera adjust exposure
      await Future.delayed(const Duration(milliseconds: 500));

      // Capture
      final xFile = await controller.takePicture();

      // Save to app's temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = '${label}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(tempDir.path, fileName);

      final file = await File(xFile.path).copy(filePath);
      print('[Camera] $label photo captured: $filePath');
      return file;
    } catch (e) {
      print('[Camera] $label capture failed: $e');
      return null; // per spec: if one fails, continue with the other
    } finally {
      // Always release camera hardware
      await controller?.dispose();
    }
  }
}
