import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LocalQueueService {
  static Database? _database;
  static const String tableName = 'local_clients';
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
        version: 1,
        onCreate: _onCreate,
      );
    } else {
      try {
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, 'waiting_room.db');
        return await openDatabase(
          path,
          version: 1,
          onCreate: _onCreate,
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
          version: 1,
          onCreate: _onCreate,
        );
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE $tableName (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  lat REAL,
  lng REAL,
  created_at TEXT NOT NULL,
  is_synced INTEGER NOT NULL DEFAULT 0
)
''');
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

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}