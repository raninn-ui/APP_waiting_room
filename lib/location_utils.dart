// lib/location_utils.dart
import 'dart:math' show cos, sqrt, asin;

/// Simple approximation of Haversine distance in kilometers
/// 
/// Calculates the great-circle distance between two points on Earth
/// given their latitude and longitude coordinates.
/// 
/// Parameters:
///   - lat1: Latitude of the first point in degrees
///   - lon1: Longitude of the first point in degrees
///   - lat2: Latitude of the second point in degrees
///   - lon2: Longitude of the second point in degrees
/// 
/// Returns:
///   Distance in kilometers
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // Math.PI / 180
  final c = cos;
  final a = 0.5 - c((lat2 - lat1) * p)/2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p))/2;
  return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
}

