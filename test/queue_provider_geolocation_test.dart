import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workshop5/geolocation_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

@GenerateMocks([
  GeolocationService,
])
import 'queue_provider_geolocation_test.mocks.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  test('GeolocationService mock returns position', () async {
    final mockGeo = MockGeolocationService();

    final mockPos = Position(
      latitude: 37.7749,
      longitude: -122.4194,
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      timestamp: DateTime.now(),
      floor: null,
      isMocked: false,
    );
    when(mockGeo.getCurrentPosition()).thenAnswer((_) async => mockPos);

    final position = await mockGeo.getCurrentPosition();

    expect(position, isNotNull);
    expect(position!.latitude, 37.7749);
    expect(position.longitude, -122.4194);
  });
}
