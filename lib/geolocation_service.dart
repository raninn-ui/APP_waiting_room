import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class GeolocationService {
  // Default test location (New York City) when GPS is unavailable
  static const double defaultLat = 40.7128;
  static const double defaultLng = -74.0060;

  Future<Position?> getCurrentPosition() async {
    try {
      // 1. Check & request permission
      debugPrint('📍 Checking location permission...');
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        debugPrint('📍 Requesting location permission...');
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission denied forever - using default test location');
        return Position(
          latitude: defaultLat,
          longitude: defaultLng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        debugPrint('⚠️ Location permission not granted: $permission - using default test location');
        return Position(
          latitude: defaultLat,
          longitude: defaultLng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      // 2. Ensure location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled - using default test location');
        debugPrint('💡 To use real GPS: Enable Location in device Settings');
        // Return a mock position for testing when GPS is disabled
        return Position(
          latitude: defaultLat,
          longitude: defaultLng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      // 3. Fetch position with timeout
      debugPrint('📍 Fetching current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      ).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          debugPrint('⚠️ Location fetch timed out');
          throw Exception('Location timeout');
        },
      );

      debugPrint('✅ Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('⚠️ Geolocation error: $e - using default test location');
      // Return default position even on error (for offline/testing)
      return Position(
        latitude: defaultLat,
        longitude: defaultLng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }
}