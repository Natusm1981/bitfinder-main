import 'package:sqflite/sqflite.dart';

class PoolCompletedInterval {
  final String signature;
  final BigInt sequenceStart;
  final BigInt sequenceEnd;
  final BigInt keyCount;
  final DateTime updatedAt;

  const PoolCompletedInterval({
    required this.signature,
    required this.sequenceStart,
    required this.sequenceEnd,
    required this.keyCount,
    required this.updatedAt,
  });

  bool contains(BigInt sequenceIndex) =>
      sequenceIndex >= sequenceStart && sequenceIndex <= sequenceEnd;
}

class PoolStorageService {
  static const String _databaseName = 'bit_finder_pool.db';
  static const int _databaseVersion = 1;

  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) return existing;
    final path = '${await getDatabasesPath()}/$_databaseName';
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pool_completed_intervals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            signature TEXT NOT NULL,
            sequence_start TEXT NOT NULL,
            sequence_end TEXT NOT NULL,
            key_count TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_pool_intervals_signature_start '
          'ON pool_completed_intervals(signature, sequence_start)',
        );
      },
    );
    return _database!;
  }

  Future<List<PoolCompletedInterval>> loadCompletedIntervals(
    String signature,
  ) async {
    final db = await _db;
    final rows = await db.query(
      'pool_completed_intervals',
      where: 'signature = ?',
      whereArgs: [signature],
      orderBy: 'LENGTH(sequence_start), sequence_start',
    );
    return rows.map(_intervalFromRow).toList(growable: false);
  }

  Future<List<PoolCompletedInterval>> addCompletedInterval({
    required String signature,
    required BigInt sequenceStart,
    required BigInt sequenceEnd,
  }) async {
    final db = await _db;
    final intervals = await loadCompletedIntervals(signature);
    var mergedStart = sequenceStart;
    var mergedEnd = sequenceEnd;
    final overlappingIds = <int>[];

    final rows = await db.query(
      'pool_completed_intervals',
      where: 'signature = ?',
      whereArgs: [signature],
    );

    for (final row in rows) {
      final id = row['id'] as int;
      final start = BigInt.parse(row['sequence_start'] as String);
      final end = BigInt.parse(row['sequence_end'] as String);
      final touches = start <= mergedEnd + BigInt.one &&
          end + BigInt.one >= mergedStart;
      if (!touches) continue;
      if (start < mergedStart) mergedStart = start;
      if (end > mergedEnd) mergedEnd = end;
      overlappingIds.add(id);
    }

    await db.transaction((txn) async {
      if (overlappingIds.isNotEmpty) {
        await txn.delete(
          'pool_completed_intervals',
          where:
              'id IN (${List.filled(overlappingIds.length, '?').join(',')})',
          whereArgs: overlappingIds,
        );
      }
      await txn.insert('pool_completed_intervals', {
        'signature': signature,
        'sequence_start': mergedStart.toString(),
        'sequence_end': mergedEnd.toString(),
        'key_count': (mergedEnd - mergedStart + BigInt.one).toString(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    });

    if (intervals.isEmpty && overlappingIds.isEmpty) {
      // Fast path still reloads below to keep ordering canonical.
    }
    return loadCompletedIntervals(signature);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  PoolCompletedInterval _intervalFromRow(Map<String, Object?> row) {
    return PoolCompletedInterval(
      signature: row['signature'] as String,
      sequenceStart: BigInt.parse(row['sequence_start'] as String),
      sequenceEnd: BigInt.parse(row['sequence_end'] as String),
      keyCount: BigInt.parse(row['key_count'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
