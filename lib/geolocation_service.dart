import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class GeolocationService {

  /// Request location permission at app startup
  Future<void> requestPermissionAtStartup() async {
    try {
      debugPrint('📍 Requesting location permission at startup...');
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Show permission popup automatically
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          debugPrint('✅ Location permission granted!');
        } else {
          debugPrint('⚠️ Location permission denied by user');
        }
      } else if (permission == LocationPermission.whileInUse ||
                 permission == LocationPermission.always) {
        debugPrint('✅ Location permission already granted');
      } else {
        debugPrint('⚠️ Location permission: $permission');
      }
    } catch (e) {
      debugPrint('❌ Error requesting location permission: $e');
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      debugPrint('Checking location permission...');
      final permission = await Geolocator.checkPermission();

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        debugPrint('Location permission not granted');
        return null;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled');
        return null;
      }

      debugPrint('Fetching real GPS position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Location timeout');
        },
      );

      debugPrint('Real GPS location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('GPS error: $e');
      return null;
    }
  }
}