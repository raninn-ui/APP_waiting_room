import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workshop5/queue_provider.dart';
import 'package:workshop5/geolocation_service.dart';
import 'package:workshop5/local_queue_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:postgrest/postgrest.dart';

@GenerateMocks([
  GeolocationService,
  SupabaseClient,
  SupabaseQueryBuilder,
  PostgrestFilterBuilder,
])
import 'queue_provider_geolocation_test.mocks.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  test('addClient saves client with geolocation', () async {
    final mockGeo = MockGeolocationService();
    final mockSupabase = MockSupabaseClient();
    final mockQueryBuilder = MockSupabaseQueryBuilder();
    final mockPostgrest = MockPostgrestFilterBuilder();

    when(mockSupabase.from(any)).thenReturn(mockQueryBuilder);
    when(mockQueryBuilder.upsert(any)).thenReturn(mockPostgrest); // <-- SYNCHRONE

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

    final provider = QueueProvider(
      geoService: mockGeo,
      localDb: LocalQueueService(inMemory: true),
      supabaseClient: mockSupabase,
    );

    await provider.addClient('Test User');
    final client = provider.clients.last;
    expect(client['lat'], 37.7749);
    expect(client['lng'], -122.4194);
    expect(client['name'], 'Test User');
    expect(client.containsKey('is_synced'), true);
  });
}
