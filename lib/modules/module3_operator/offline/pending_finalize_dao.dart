import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'pending_finalize_record.dart';

class PendingFinalizeDao {
  static const _dbName = 'offline_queue.db';
  static const _dbVersion = 2;
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    final dbDir = await getDatabasesPath();
    final dbPath = join(dbDir, _dbName);

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_finalize (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          screen_id TEXT,
          customer_id TEXT,
          total_weight REAL,
          entry_type TEXT,
          created_at INTEGER
        )
      ''');
      },
    );

    return _db!;
  }

  Future<int> update(PendingFinalizeRecord r) async {
    final db = await database;

    return db.update(
      'pending_finalize',
      r.toMap(),
      where: 'id = ?',
      whereArgs: [r.id],
    );
  }

  Future<int> insert(PendingFinalizeRecord r) async {
    final db = await database;
    return db.insert('pending_finalize', r.toMap());
  }

  Future<List<PendingFinalizeRecord>> getAll() async {
    final db = await database;
    final rows = await db.query('pending_finalize', orderBy: 'created_at ASC');
    return rows.map(PendingFinalizeRecord.fromMap).toList();
  }

  Future<int> deleteById(int id) async {
    final db = await database;
    return db.delete('pending_finalize', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('pending_finalize');
  }
}

