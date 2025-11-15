// test/location_utils_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop5/location_utils.dart';

void main() {
  group('calculateDistance', () {
    test('returns non-zero distance for different coordinates', () {
      // Distance from (0,0) to (0.001, 0.001)
      final distance = calculateDistance(0, 0, 0.001, 0.001);
      
      expect(distance, greaterThan(0));
      expect(distance, lessThan(1)); // Should be less than 1 km
    });

    test('returns zero distance for same coordinates', () {
      final distance = calculateDistance(40.7128, -74.0060, 40.7128, -74.0060);
      
      expect(distance, closeTo(0, 0.001));
    });

    test('calculates correct distance between NYC and Brooklyn', () {
      // Downtown NYC: 40.7128, -74.0060
      // Brooklyn: 40.6782, -73.9442
      final distance = calculateDistance(40.7128, -74.0060, 40.6782, -73.9442);
      
      // Expected distance is approximately 6-7 km
      expect(distance, greaterThan(5));
      expect(distance, lessThan(10));
    });

    test('calculates correct distance between known cities', () {
      // New York City: 40.7128, -74.0060
      // Los Angeles: 34.0522, -118.2437
      final distance = calculateDistance(40.7128, -74.0060, 34.0522, -118.2437);
      
      // Expected distance is approximately 3944 km
      expect(distance, greaterThan(3900));
      expect(distance, lessThan(4000));
    });

    test('handles negative coordinates correctly', () {
      // Test with southern hemisphere coordinates
      final distance = calculateDistance(-33.8688, 151.2093, -37.8136, 144.9631);
      
      // Sydney to Melbourne is approximately 714 km
      expect(distance, greaterThan(700));
      expect(distance, lessThan(750));
    });

    test('distance is symmetric', () {
      final distance1 = calculateDistance(40.7128, -74.0060, 34.0522, -118.2437);
      final distance2 = calculateDistance(34.0522, -118.2437, 40.7128, -74.0060);
      
      expect(distance1, closeTo(distance2, 0.001));
    });
  });
}

