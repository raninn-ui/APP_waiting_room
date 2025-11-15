import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class GeolocationService {
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
        debugPrint('⚠️ Location permission denied forever');
        return null;
      }

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        debugPrint('⚠️ Location permission not granted: $permission');
        return null;
      }

      // 2. Ensure location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled');
        return null;
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
      debugPrint('⚠️ Geolocation error: $e');
      return null;
    }
  }
}