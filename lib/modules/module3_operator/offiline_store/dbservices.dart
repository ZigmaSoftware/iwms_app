import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:iwms_citizen_app/data/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DB {
  DB._();
  static final DB instance = DB._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "operator_app.db");

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );

    return _database!;
  }

  Future _createDB(Database db, int version) async {
    await db.execute("""
      CREATE TABLE operator_user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unique_id TEXT,
        username TEXT UNIQUE,
        emp_id TEXT,
        name TEXT,
        role TEXT,
        access_token TEXT,
        password_hash TEXT
      );
    """);
  }
}
// class UserModeloperator {
//   final String uniqueId;
//   final String username;
//   final String name;
//   final String role;
//   final String accessToken;

//   UserModeloperator({
//     required this.uniqueId,
//     required this.username,
//     required this.name,
//     required this.role,
//     required this.accessToken,
//   });

//   factory UserModeloperator.fromApi(Map<String, dynamic> json) {
//     return UserModeloperator(
//       uniqueId: json["unique_id"],
//       username: json["username"],
//       name: json["name"],
//       role: json["role"],
//       accessToken: json["access_token"],
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         "unique_id": uniqueId,
//         "username": username,
//         "name": name,
//         "role": role,
//         "access_token": accessToken,
//       };

//   factory UserModeloperator.fromDB(Map<String, dynamic> map) {
//     return UserModeloperator(
//       uniqueId: map["unique_id"],
//       username: map["username"],
//       name: map["name"],
//       role: map["role"],
//       accessToken: map["access_token"],
//     );
//   }
// }
Future<void> saveOperatorToDB(Map<String, dynamic> apiData, String password) async {
  final db = await DB.instance.database;
  final passHash = sha256.convert(utf8.encode(password)).toString();

  await db.insert(
    "operator_user",
    {
      "unique_id": apiData["unique_id"]?.toString(),
      "username": apiData["username"]?.toString(),
      "name": apiData["name"]?.toString(),
      "role": apiData["role"]?.toString(),
      "access_token": apiData["access_token"]?.toString(),
      "emp_id": apiData["emp_id"]?.toString(),
      "password_hash": passHash,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
Future<Map<String, dynamic>?> getOperatorFromDB(String username) async {
  final db = await DB.instance.database;

  final res = await db.query(
    "operator_user",
    where: "username = ?",
    whereArgs: [username],
    limit: 1,
  );

  if (res.isEmpty) return null;

  return res.first;
}
