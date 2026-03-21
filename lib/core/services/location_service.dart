import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Request permission and get current position.
  /// Returns null if permission denied or GPS unavailable.
  static Future<Position?> getCurrentLocation() async {
    try {
      final permission = await _ensurePermission();
      if (!permission) {
        print('[GPS] Permission denied');
        return null;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } on TimeoutException {
        print('[GPS] High-accuracy fix timed out, trying fallback...');
      }

      // Fallback to last known location if live fix is slow/unavailable.
      position ??= await Geolocator.getLastKnownPosition();

      // Final fallback: lower accuracy with a short timeout.
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      print('[GPS] Got location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('[GPS] Failed to get location: $e');
      return null;
    }
  }

  static Future<bool> _ensurePermission() async {
    // Check if location services are enabled at system level
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('[GPS] Location services disabled on device');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    // If denied, request it
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    // If permanently denied, user must go to settings
    if (permission == LocationPermission.deniedForever) {
      print(
        '[GPS] Permission permanently denied — user must enable in settings',
      );
      return false;
    }

    return true;
  }
}
