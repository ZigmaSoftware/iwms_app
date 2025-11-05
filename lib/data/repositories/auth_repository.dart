// lib/data/repositories/auth_repository.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iwms_citizen_app/data/models/user_model.dart';

class AuthRepository {
  // ignore: unused_field
  final Dio _dio;
  final SharedPreferences _prefs;

  static const String _userKey = 'authenticated_user';
  static const String _roleKey = 'user_role';
  static const String _nameKey = 'user_name';
  static const String _tokenKey = 'auth_token';

  AuthRepository(this._dio, this._prefs);

  Future<void> initialize() async {
    // Reserved for future init work (e.g., token refresh)
  }

  // Remote authentication disabled for the current demo build.
  Future<UserModel> registerCitizen({
    required String phone,
    required String ownerName,
    required String contactNo,
    required String buildingNo,
    required String street,
    required String area,
    required String pincode,
    required String city,
    required String district,
    required String state,
    required String zone,
    required String ward,
    required String propertyName,
  }) async =>
      throw UnimplementedError('Remote registration disabled in demo build.');

  Future<UserModel> loginCitizen({required String phone}) async =>
      throw UnimplementedError('Remote citizen login disabled in demo build.');

  Future<UserModel> loginDriver({
    required String userName,
    required String password,
  }) async =>
      throw UnimplementedError('Remote driver login disabled in demo build.');

  Future<UserModel?> getAuthenticatedUser() async {
    final userId = _prefs.getString(_userKey);
    final role = _prefs.getString(_roleKey);
    final userName = _prefs.getString(_nameKey);

    if (userId != null && role != null && userName != null) {
      final token = _prefs.getString(_tokenKey);
      return UserModel(
        userId: userId,
        userName: userName,
        role: role,
        authToken: token,
      );
    }
    return null;
  }

  Future<void> logout() async {
    await _prefs.remove(_userKey);
    await _prefs.remove(_roleKey);
    await _prefs.remove(_nameKey);
    await _prefs.remove(_tokenKey);
  }

  Future<void> saveUser(UserModel user) async {
    await _persistUser(user);
  }

  Future<void> _persistUser(UserModel user) async {
    await _prefs.setString(_userKey, user.userId);
    await _prefs.setString(_roleKey, user.role);
    await _prefs.setString(_nameKey, user.userName);

    if (user.authToken != null && user.authToken!.isNotEmpty) {
      await _prefs.setString(_tokenKey, user.authToken!);
    } else {
      await _prefs.remove(_tokenKey);
    }
  }
}
