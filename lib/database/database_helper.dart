import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0;

    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }


  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tb_xi.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL,
            created_at TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            location_radius REAL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            type TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE matches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_id INTEGER NOT NULL,
            requester_user_id INTEGER NOT NULL,
            owner_user_id INTEGER NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            confirmed_at TEXT,
            FOREIGN KEY (item_id) REFERENCES items(id),
            FOREIGN KEY (requester_user_id) REFERENCES users(id),
            FOREIGN KEY (owner_user_id) REFERENCES users(id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE users ADD COLUMN latitude REAL',
          );
          await db.execute(
            'ALTER TABLE users ADD COLUMN longitude REAL',
          );
          await db.execute(
            'ALTER TABLE users ADD COLUMN location_radius REAL DEFAULT 1',
          );
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              description TEXT,
              type TEXT NOT NULL,
              latitude REAL,
              longitude REAL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users(id)
            )
          ''');
        }

        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE matches (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              item_id INTEGER NOT NULL,
              requester_user_id INTEGER NOT NULL,
              owner_user_id INTEGER NOT NULL,
              status TEXT NOT NULL,
              created_at TEXT NOT NULL,
              confirmed_at TEXT,
              FOREIGN KEY (item_id) REFERENCES items(id),
              FOREIGN KEY (requester_user_id) REFERENCES users(id),
              FOREIGN KEY (owner_user_id) REFERENCES users(id)
            )
          ''');
        }
      },
    );
  }

  Future<int> createUser({
    required String name,
    required String phone,
    required String email,
  }) async {
    final db = await database;

    return await db.insert(
      'users',
      {
        'name': name,
        'phone': phone,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Map<String, dynamic>?> getUserByPhone(
    String phone,
  ) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<int> createItem({
    required int userId,
    required String name,
    required String description,
    required String type,
    double? latitude,
    double? longitude,
  }) async {
    final db = await database;

    return await db.insert(
      'items',
      {
        'user_id': userId,
        'name': name,
        'description': description,
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;

    return await db.query(
      'items',
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> findMatches({
    required int itemId,
    required String type,
    required String name,
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final candidates = await getPotentialMatches(
      type: type,
      name: name,
    );

    final matches = <Map<String, dynamic>>[];

    for (final item in candidates) {
      final itemLatitude =
          (item['latitude'] as num?)?.toDouble();

      final itemLongitude =
          (item['longitude'] as num?)?.toDouble();

      if (itemLatitude == null || itemLongitude == null) {
        continue;
      }

      final distance = calculateDistanceKm(
        latitude,
        longitude,
        itemLatitude,
        itemLongitude,
      );

      if (distance <= radiusKm) {
        matches.add({
          ...item,
          'distance_km': distance,
        });
      }
    }

    return matches;
  }

  Future<List<Map<String, dynamic>>> getPendingMatches({
    required int ownerUserId,
  }) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT
        m.id AS match_id,
        m.item_id,
        m.requester_user_id,
        m.owner_user_id,
        m.status,
        m.created_at,
        i.name,
        i.description,
        i.type
      FROM matches m
      INNER JOIN items i
        ON i.id = m.item_id
      WHERE m.owner_user_id = ?
        AND m.status = 'PENDING'
      ORDER BY m.id DESC
    ''', [ownerUserId]);
  }

  Future<int> createMatch({
    required int itemId,
    required int requesterUserId,
    required int ownerUserId,
  }) async {
    final db = await database;

    return await db.insert(
      'matches',
      {
        'item_id': itemId,
        'requester_user_id': requesterUserId,
        'owner_user_id': ownerUserId,
        'status': 'PENDING',
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<bool> hasActiveMatch({
    required int itemId,
    required int requesterUserId,
    required int ownerUserId,
  }) async {
    final db = await database;

    final rows = await db.query(
      'matches',
      where: '''
        item_id = ?
        AND requester_user_id = ?
        AND owner_user_id = ?
        AND status IN (?, ?)
      ''',
      whereArgs: [
        itemId,
        requesterUserId,
        ownerUserId,
        'PENDING',
        'ACCEPTED',
      ],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<int> updateMatchStatus({
    required int matchId,
    required String status,
  }) async {
    final db = await database;

    final data = <String, dynamic>{
      'status': status,
    };

    if (status == 'ACCEPTED') {
      data['confirmed_at'] =
          DateTime.now().toIso8601String();
    }

    return await db.update(
      'matches',
      data,
      where: 'id = ?',
      whereArgs: [matchId],
    );
  }

  Future<List<Map<String, dynamic>>> getAcceptedMatches({
    required int userId,
  }) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT
        m.id AS match_id,
        m.item_id,
        m.requester_user_id,
        m.owner_user_id,
        m.status,
        m.created_at,
        m.confirmed_at,
        i.name,
        i.description,
        i.type
      FROM matches m
      INNER JOIN items i
        ON i.id = m.item_id
      WHERE
        m.status = 'ACCEPTED'
        AND (
          m.requester_user_id = ?
          OR m.owner_user_id = ?
        )
      ORDER BY m.id DESC
    ''', [userId, userId]);
  }

  Future<List<Map<String, dynamic>>> getPotentialMatches({
    required String type,
    required String name,
  }) async {
    final db = await database;

    final oppositeType = type == 'BUTUH'
        ? 'PUNYA'
        : 'BUTUH';

    return await db.query(
      'items',
      where: 'type = ? AND LOWER(name) = LOWER(?)',
      whereArgs: [
        oppositeType,
        name.trim(),
      ],
      orderBy: 'id DESC',
    );
  }
}
