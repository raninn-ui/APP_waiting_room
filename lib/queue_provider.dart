import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'models/client.dart';
import 'local_queue_service.dart';
import 'geolocation_service.dart';
import 'location_utils.dart';

class QueueProvider extends ChangeNotifier {
  final SupabaseClient _supabase;
  final LocalQueueService _localDb;
  final GeolocationService _geoService;

  late RealtimeChannel _channel;
  final List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> get clients => List.unmodifiable(_clients);

  // Room management
  final List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> get rooms => List.unmodifiable(_rooms);

  // Track current active room
  String? _currentRoomId;
  String? get currentRoomId => _currentRoomId;

  /// Get room name by room ID
  String getRoomName(String? roomId) {
    if (roomId == null) return 'Unknown Room';
    try {
      final room = _rooms.firstWhere((r) => r['id'] == roomId);
      return room['name'] ?? 'Unknown Room';
    } catch (e) {
      return 'Unknown Room';
    }
  }

  Timer? _periodicSyncTimer;
  Timer? _periodicWebRefreshTimer;

  QueueProvider({
    SupabaseClient? supabaseClient,
    GeolocationService? geoService,
    LocalQueueService? localDb,
  })  : _supabase = supabaseClient ?? Supabase.instance.client,
        _geoService = geoService ?? GeolocationService(),
        _localDb = localDb ?? LocalQueueService();

  /// Set up connectivity listener to trigger sync when coming back online
  void setupConnectivityListener(void Function() onConnectivityChanged) {
    // This will be called from main.dart when ConnectivityService changes
    onConnectivityChanged();
  }

  /// Trigger sync when connectivity is restored
  Future<void> onConnectivityRestored() async {
    debugPrint('🔄 Connectivity restored, triggering sync...');
    await _syncLocalToRemote();
    // Reload queue to get latest data
    await _loadQueue();
  }

  /// Initialize queue (local + remote + realtime)
  Future<void> initialize() async {
    // Load waiting rooms first
    await fetchWaitingRooms();

    await _loadQueue();

    // 🔁 Start periodic background sync (native platforms only)
    if (!kIsWeb) {
      _periodicSyncTimer?.cancel();
      _periodicSyncTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
        try {
          final unsynced = await _localDb.getUnsyncedClients();
          if (unsynced.isNotEmpty) {
            await _syncLocalToRemote();
            final updated = await _localDb.getClients();
            _clients
              ..clear()
              ..addAll(updated);
            _clients.sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Periodic sync error: $e');
        }
      });
    } else {
      // Web: periodic remote refresh to keep list updated if realtime is blocked
      _periodicWebRefreshTimer?.cancel();
      _periodicWebRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        await _refreshFromRemoteWeb();
      });

      // Force immediate refresh once more after init
      unawaited(_refreshFromRemoteWeb());
    }
  }

  Future<void> _refreshFromRemoteWeb() async {
    if (!kIsWeb) return;
    try {
      final list = await _supabase
          .from('clients')
          .select()
          .order('created_at');
      final remoteClients = (list as List<dynamic>)
          .map((e) => {...Map<String, dynamic>.from(e), 'is_synced': 1})
          .toList();
      _clients
        ..clear()
        ..addAll(remoteClients);
      _clients.sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));
      notifyListeners();
    } catch (e) {
      debugPrint('Web fetch error: $e');
    }
  }

  Future<void> _loadQueue() async {
    try {
      if (kIsWeb) {
        // Web: no local SQLite → load remote only, then subscribe realtime
        final response = await _supabase
            .from('clients')
            .select()
            .order('created_at');
        final remoteClients = (response as List<dynamic>)
            .map((e) => {...Map<String, dynamic>.from(e), 'is_synced': 1})
            .toList();
        _clients
          ..clear()
          ..addAll(remoteClients);
        _clients.sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));
        notifyListeners();
        _setupRealtimeSubscription();
        return;
      }

      // 1️⃣ Load local clients (native)
      try {
        debugPrint('📂 Loading local clients from SQLite...');
        final localClients = await _localDb.getClients();
        debugPrint('✅ Loaded ${localClients.length} local clients');
        _clients
          ..clear()
          ..addAll(localClients);
      } catch (e) {
        debugPrint('⚠️ Error loading local clients: $e');
        // Continue even if local DB fails
      }

      // 2️⃣ Load remote clients from Supabase
      try {
        debugPrint('🌐 Loading remote clients from Supabase...');
        final response = await _supabase
            .from('clients')
            .select()
            .order('created_at');
        final remoteClients = (response as List<dynamic>)
            .map((e) => {...Map<String, dynamic>.from(e), 'is_synced': 1})
            .toList();
        debugPrint('✅ Loaded ${remoteClients.length} remote clients');

        // Insert into local DB if not already present
        for (var rc in remoteClients) {
          if (!_clients.any((c) => c['id'] == rc['id'])) {
            try {
              await _localDb.insertClientLocally(rc);
              _clients.add(rc);
            } catch (e) {
              debugPrint('⚠️ Error inserting client ${rc['id']} locally: $e');
              // Add to memory even if local insert fails
              _clients.add(rc);
            }
          }
        }

        _clients.sort(
                (a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));
        notifyListeners();
      } catch (e) {
        debugPrint('⚠️ Error loading remote clients: $e');
        // Continue with local clients only
        notifyListeners();
      }

      // 3️⃣ Sync unsynced local clients to Supabase
      try {
        await _syncLocalToRemote();
      } catch (e) {
        debugPrint('⚠️ Error syncing to remote: $e');
      }

      // 4️⃣ Setup Realtime subscription
      try {
        _setupRealtimeSubscription();
      } catch (e) {
        debugPrint('⚠️ Error setting up realtime: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Critical error loading queue: $e');
      debugPrint('Stack trace: $stackTrace');
      // Ensure UI is notified even on error
      notifyListeners();
    }
  }

  Future<void> _syncLocalToRemote() async {
    if (kIsWeb) return; // no local DB to sync on web
    try {
      final unsynced = await _localDb.getUnsyncedClients();

      for (var client in unsynced) {
        try {
          final remoteClient = Map<String, dynamic>.from(client)..remove('is_synced');
          await _supabase.from('clients').upsert(remoteClient);
          await _localDb.markClientAsSynced(client['id'] as String);
        } catch (e) {
          debugPrint('Sync failed for ${client['id']}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error syncing queue: $e');
    }
  }

  /// Fetch all waiting rooms from Supabase (with offline fallback)
  Future<void> fetchWaitingRooms() async {
    try {
      // First, try to load from local cache
      final localRooms = await _localDb.getWaitingRooms();
      if (localRooms.isNotEmpty) {
        _rooms.clear();
        _rooms.addAll(localRooms);
        debugPrint('✅ Loaded ${_rooms.length} waiting rooms from local cache');
        notifyListeners();
      }

      // Then try to fetch from remote (if online)
      try {
        debugPrint('🏥 Fetching waiting rooms from Supabase...');
        final response = await _supabase
            .from('waiting_rooms')
            .select()
            .order('name');

        final remoteRooms = (response as List<dynamic>).cast<Map<String, dynamic>>();

        // Save to local cache for offline use
        await _localDb.saveWaitingRooms(remoteRooms);

        _rooms.clear();
        _rooms.addAll(remoteRooms);
        debugPrint('✅ Loaded ${_rooms.length} waiting rooms from Supabase');
        notifyListeners();
      } catch (e) {
        debugPrint('⚠️ Could not fetch from Supabase (offline?): $e');
        // If we already have local rooms, that's fine
        if (_rooms.isNotEmpty) {
          debugPrint('✅ Using ${_rooms.length} cached waiting rooms (offline mode)');
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching waiting rooms: $e');
    }
  }

  /// Find the nearest waiting room to the given coordinates
  Future<String?> _findNearestRoom(double clientLat, double clientLng) async {
    if (_rooms.isEmpty) await fetchWaitingRooms();

    if (_rooms.isEmpty) {
      debugPrint('⚠️ No waiting rooms available');
      return null;
    }

    double minDistance = double.infinity;
    String? nearestRoomId;

    for (var room in _rooms) {
      final roomLat = room['latitude'] as double;
      final roomLng = room['longitude'] as double;
      final distance = calculateDistance(clientLat, clientLng, roomLat, roomLng);

      debugPrint('📏 Distance to ${room['name']}: ${distance.toStringAsFixed(2)} km');

      if (distance < minDistance) {
        minDistance = distance;
        nearestRoomId = room['id'] as String;
      }
    }

    debugPrint('✅ Nearest room: $nearestRoomId (${minDistance.toStringAsFixed(2)} km)');
    return nearestRoomId;
  }

  Future<void> addClient(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    debugPrint('📍 Getting location for new client...');
    final position = await _geoService.getCurrentPosition();

    // Use position from GeolocationService (which has default fallback built-in)
    final clientLat = position?.latitude ?? 40.7128; // NYC default
    final clientLng = position?.longitude ?? -74.0060; // NYC default

    if (position != null) {
      debugPrint('✅ Location obtained: $clientLat, $clientLng');
    } else {
      debugPrint('⚠️ Location not available, using default NYC location ($clientLat, $clientLng)');
    }

    // Find nearest room based on location (AUTO-ASSIGNMENT)
    final roomId = await _findNearestRoom(clientLat, clientLng);

    // Check if room was found before inserting
    if (roomId == null) {
      debugPrint('❌ No waiting room found, cannot add client');
      return;
    }

    debugPrint('🎯 Auto-assigned to nearest room: $roomId');

    final newClient = {
      'id': const Uuid().v4(),
      'name': trimmed,
      'lat': clientLat,
      'lng': clientLng,
      'waiting_room_id': roomId,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      // 1️⃣ Insert directly on Supabase (use insert instead of upsert)
      debugPrint('➕ Inserting client to Supabase: $trimmed (room: $roomId)');
      await _supabase.from('clients').insert(newClient);
      debugPrint('✅ Client inserted to Supabase successfully');

      if (kIsWeb) {
        // Web: ensure immediate consistency by refetching from remote
        await _refreshFromRemoteWeb();
        return;
      }

      // 2️⃣ Insert locally marked as synced (native)
      await _localDb.insertClientLocally({...newClient, 'is_synced': 1});

      // 3️⃣ Update UI
      _clients.add({...newClient, 'is_synced': 1});
      _clients.sort((a, b) =>
          (a['created_at'] as String).compareTo(b['created_at'] as String));
      notifyListeners();
      debugPrint('✅ Client added to local list');
    } catch (e) {
      debugPrint('❌ Error adding client to Supabase: $e');

      if (!kIsWeb) {
        // If Supabase fails (native), store locally as unsynced
        await _localDb.insertClientLocally({...newClient, 'is_synced': 0});
        _clients.add({...newClient, 'is_synced': 0});
        _clients.sort((a, b) =>
            (a['created_at'] as String).compareTo(b['created_at'] as String));
        notifyListeners();

        // 🔁 Trigger background sync retry when connectivity returns
        unawaited(_syncLocalToRemote());
      }
    }
  }

  Future<void> removeClient(String id) async {
    try {
      debugPrint('🗑️ Removing client from Supabase: $id');
      // Remove from Supabase
      await _supabase.from('clients').delete().eq('id', id);
      debugPrint('✅ Client removed from Supabase');

      if (!kIsWeb) {
        // Remove from local DB (native)
        final db = await _localDb.database;
        await db.delete(LocalQueueService.tableName, where: 'id = ?', whereArgs: [id]);
        debugPrint('✅ Client removed from local DB');
      }

      _clients.removeWhere((c) => c['id'] == id);
      notifyListeners();
      debugPrint('✅ Client removed from UI');
    } catch (e) {
      debugPrint('❌ Failed to remove client: $e');
    }
  }

  Future<void> nextClient() async {
    if (_clients.isEmpty) return;
    final first = _clients.first;
    await removeClient(first['id'] as String);
  }

  void _setupRealtimeSubscription({String? roomId}) {
    _channel = _supabase.channel('clients_channel');

    _channel.onPostgresChanges(
      schema: 'public',
      table: 'clients',
      event: PostgresChangeEvent.all,
      callback: (payload) async {
        final event = payload.eventType;
        final record = payload.newRecord ?? payload.oldRecord;

        if (record == null) return;

        // Filter by room if roomId is specified
        if (roomId != null && record['waiting_room_id'] != roomId) {
          return;
        }

        if (event == PostgresChangeEvent.insert) {
          if (!_clients.any((c) => c['id'] == record['id'])) {
            if (!kIsWeb) {
              await _localDb.insertClientLocally({
                ...Map<String, dynamic>.from(record),
                'is_synced': 1,
              });
            }
            _clients.add({...record, 'is_synced': 1});
            _clients.sort((a, b) =>
                (a['created_at'] as String).compareTo(b['created_at'] as String));
            notifyListeners();
          }
        } else if (event == PostgresChangeEvent.delete) {
          final id = record['id'] as String?;
          if (id != null) {
            if (!kIsWeb) {
              final db = await _localDb.database;
              await db.delete(LocalQueueService.tableName, where: 'id = ?', whereArgs: [id]);
            }
            _clients.removeWhere((c) => c['id'] == id);
            notifyListeners();
          }
        }
      },
    );

    _channel.subscribe();
  }

  /// Subscribe to a specific waiting room's realtime updates
  /// This cancels the current subscription and creates a new one filtered by roomId
  void subscribeToRoom(String roomId) {
    try {
      debugPrint('🔄 Subscribing to room: $roomId');

      // Track the current room
      _currentRoomId = roomId;

      // Cancel old subscription
      _channel.unsubscribe();

      // Load clients for this specific room
      _loadClientsForRoom(roomId);

      // Create new channel with room-specific filter
      // Note: Supabase realtime filters work at the database level
      _channel = _supabase.channel('room_${roomId}_channel');

      _channel.onPostgresChanges(
        schema: 'public',
        table: 'clients',
        event: PostgresChangeEvent.all,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'waiting_room_id',
          value: roomId,
        ),
        callback: (payload) async {
          final event = payload.eventType;
          final record = payload.newRecord ?? payload.oldRecord;

          if (record == null) return;

          if (event == PostgresChangeEvent.insert) {
            if (!_clients.any((c) => c['id'] == record['id'])) {
              if (!kIsWeb) {
                await _localDb.insertClientLocally({
                  ...Map<String, dynamic>.from(record),
                  'is_synced': 1,
                });
              }
              _clients.add({...record, 'is_synced': 1});
              _clients.sort((a, b) =>
                  (a['created_at'] as String).compareTo(b['created_at'] as String));
              notifyListeners();
            }
          } else if (event == PostgresChangeEvent.delete) {
            final id = record['id'] as String?;
            if (id != null) {
              if (!kIsWeb) {
                final db = await _localDb.database;
                await db.delete(LocalQueueService.tableName, where: 'id = ?', whereArgs: [id]);
              }
              _clients.removeWhere((c) => c['id'] == id);
              notifyListeners();
            }
          }
        },
      );

      _channel.subscribe();
      debugPrint('✅ Subscribed to room: $roomId');
    } catch (e) {
      debugPrint('❌ Error subscribing to room: $e');
    }
  }

  /// Load clients for a specific room
  Future<void> _loadClientsForRoom(String roomId) async {
    try {
      debugPrint('📥 Loading clients for room: $roomId');
      final response = await _supabase
          .from('clients')
          .select()
          .eq('waiting_room_id', roomId)
          .order('created_at');

      final roomClients = (response as List<dynamic>)
          .map((e) => {...Map<String, dynamic>.from(e), 'is_synced': 1})
          .toList();

      _clients.clear();
      _clients.addAll(roomClients);
      notifyListeners();
      debugPrint('✅ Loaded ${roomClients.length} clients for room');
    } catch (e) {
      debugPrint('❌ Error loading clients for room: $e');
    }
  }

  @override
  void dispose() {
    try {
      _channel.unsubscribe();
      _periodicSyncTimer?.cancel();
      _periodicWebRefreshTimer?.cancel();
      if (!kIsWeb) {
        _localDb.close();
      }
    } catch (_) {}
    super.dispose();
  }
}
