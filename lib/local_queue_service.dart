import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalQueueService {
  static Database? _database;
  static const String tableName = 'local_clients';
  static const String roomsTableName = 'local_waiting_rooms';
  final bool _inMemory;

  LocalQueueService({bool inMemory = false}) : _inMemory = inMemory;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    if (_inMemory) {
      return await openDatabase(
        ':memory:',
        version: 4,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } else {
      try {
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, 'waiting_room.db');
        return await openDatabase(
          path,
          version: 4,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onOpen: (db) async {
            print('✅ Database opened successfully at: $path');
          },
        );
      } catch (e) {
        print('❌ Error initializing database: $e');
        // Fallback to in-memory database if file-based fails
        print('⚠️ Falling back to in-memory database');
        return await openDatabase(
          ':memory:',
          version: 4,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create clients table
    await db.execute('''
CREATE TABLE $tableName (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  lat REAL,
  lng REAL,
  created_at TEXT NOT NULL,
  waiting_room_id TEXT,
  status TEXT NOT NULL DEFAULT 'waiting',
  called_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0
)
''');

    // Create waiting rooms table for offline support
    await db.execute('''
CREATE TABLE $roomsTableName (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  created_at TEXT NOT NULL
)
''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add waiting_room_id column for version 2
      await db.execute('ALTER TABLE $tableName ADD COLUMN waiting_room_id TEXT');
      print('✅ Database upgraded to version 2: added waiting_room_id column');
    }

    if (oldVersion < 3) {
      // Create waiting rooms table for offline support (version 3)
      await db.execute('''
CREATE TABLE $roomsTableName (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  created_at TEXT NOT NULL
)
''');
      print('✅ Database upgraded to version 3: created local_waiting_rooms table for offline support');
    }

    if (oldVersion < 4) {
      // Add status and called_at columns for no-show handling (version 4)
      await db.execute('ALTER TABLE $tableName ADD COLUMN status TEXT NOT NULL DEFAULT \'waiting\'');
      await db.execute('ALTER TABLE $tableName ADD COLUMN called_at TEXT');
      print('✅ Database upgraded to version 4: added status and called_at columns for no-show handling');
    }
  }

  Future<void> insertClientLocally(Map<String, dynamic> client) async {
    final db = await database;
    await db.insert(
      tableName,
      client,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final db = await database;
    return db.query(tableName, orderBy: 'created_at ASC');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedClients() async {
    final db = await database;
    return db.query(tableName, where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<void> markClientAsSynced(String id) async {
    final db = await database;
    await db.update(
      tableName,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update client status
  Future<void> updateClientStatus(String id, String status, {String? calledAt}) async {
    final db = await database;
    final updateData = <String, dynamic>{
      'status': status,
      'is_synced': 0, // Mark as unsynced so it gets pushed to Supabase
    };

    if (calledAt != null) {
      updateData['called_at'] = calledAt;
    }

    await db.update(
      tableName,
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get clients that should be marked as no-show (called more than 30 minutes ago)
  Future<List<Map<String, dynamic>>> getClientsForNoShow(int timeoutMinutes) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(Duration(minutes: timeoutMinutes)).toIso8601String();

    return db.query(
      tableName,
      where: 'status = ? AND called_at IS NOT NULL AND called_at < ?',
      whereArgs: ['called', cutoffTime],
    );
  }

  // ========== WAITING ROOMS METHODS (for offline support) ==========

  /// Save waiting rooms to local database
  Future<void> saveWaitingRooms(List<Map<String, dynamic>> rooms) async {
    final db = await database;
    final batch = db.batch();

    for (var room in rooms) {
      batch.insert(
        roomsTableName,
        room,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    print('✅ Saved ${rooms.length} waiting rooms locally');
  }

  /// Get waiting rooms from local database
  Future<List<Map<String, dynamic>>> getWaitingRooms() async {
    final db = await database;
    return db.query(roomsTableName, orderBy: 'name ASC');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}