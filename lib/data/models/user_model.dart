// lib/data/models/user_model.dart
import 'package:equatable/equatable.dart';

// The data coming directly from the API or local database.
class UserModel extends Equatable {
  final String userId;
  final String userName;
  final String role; // e.g., "citizen", "driver", "admin"
  final String? authToken; // This is the nullable string

  const UserModel({
    required this.userId,
    required this.userName,
    required this.role,
    this.authToken, // This is now optional
  });

  // Example factory for creating a user from an API response map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      role: json['role'] as String,
      authToken: json['auth_token'] as String?, // Handles null
    );
  }

  // Helper for generating API payload (optional)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'role': role,
      'auth_token': authToken,
    };
  }

  // --- THIS IS THE FIX ---
  // Change 'List<Object>' to 'List<Object?>' to allow nulls
  @override
  List<Object?> get props => [userId, userName, role, authToken];
  // --- END FIX ---
}