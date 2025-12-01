import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'pending_record.dart';

class PendingRecordDao {
  static const _dbName = 'offline_queue.db';
  static const _dbVersion = 2;
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, _dbName);

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            screen_id TEXT,
            customer_id TEXT,
            customer_name TEXT,
            contact_no TEXT,
            waste_type_id TEXT,
            weight TEXT,
            latitude REAL,
            longitude REAL,
            image_path TEXT,
            is_update INTEGER,
            unique_id TEXT,
            created_at INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion == 1) {
          await db.execute("ALTER TABLE pending_records ADD COLUMN screen_id TEXT");
        }
      },
    );
    return _db!;
  }

  Future<int> insert(PendingRecord r) async {
    final db = await database;
    final data = r.toMap();
    data['unique_id'] ??= "uid_${DateTime.now().millisecondsSinceEpoch}";
    return db.insert('pending_records', data);
  }

  Future<List<PendingRecord>> getAll() async {
    final db = await database;
    final rows = await db.query('pending_records', orderBy: 'created_at ASC');
    return rows.map(PendingRecord.fromMap).toList();
  }

  Future<int> deleteById(int id) async {
    final db = await database;
    return db.delete('pending_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('pending_records');
  }

  Future<PendingRecord?> findByTypeAndScreen({
    required String wasteTypeId,
    required String screenId,
  }) async {
    final db = await database;
    final rows = await db.query(
      'pending_records',
      where: 'waste_type_id = ? AND screen_id = ?',
      whereArgs: [wasteTypeId, screenId],
    );

    if (rows.isEmpty) return null;
    return PendingRecord.fromMap(rows.first);
  }

  Future<List<PendingRecord>> getByScreen(String screenId) async {
    final db = await database;
    final rows = await db.query(
      'pending_records',
      where: 'screen_id=?',
      whereArgs: [screenId],
      orderBy: 'created_at ASC',
    );
    return rows.map(PendingRecord.fromMap).toList();
  }

  Future<int> deleteByScreen(String screenId) async {
    final db = await database;
    return db.delete('pending_records', where: 'screen_id=?', whereArgs: [screenId]);
  }

  Future<int> update(PendingRecord record) async {
    final db = await database;

    final data = record.toMap()
      ..remove('id')  // prevent overriding primary key
      ..update('unique_id', (v) => v ?? "uid_${record.id}");

    final rows = await db.update(
      'pending_records',
      data,
      where: 'id = ?',
      whereArgs: [record.id],
    );

    debugPrint("🔥 PendingRecord UPDATE → rows affected: $rows | id=${record.id} | uid=${record.uniqueId}");
    return rows;
  }
}
