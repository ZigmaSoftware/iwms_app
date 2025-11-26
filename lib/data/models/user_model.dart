import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String userId;
  final String userName;
  final String role;
  final String? authToken;

  const UserModel({
    required this.userId,
    required this.userName,
    required this.role,
    this.authToken,
  });

  factory UserModel.fromApi(Map<String, dynamic> json) {
    return UserModel(
      userId: json["unique_id"]?.toString() ?? "",
      userName: json["name"]?.toString() ?? "",
      role: json["role"]?.toString().toLowerCase() ?? "citizen",
      authToken: json["access_token"]?.toString(),
    );
  }

  @override
  List<Object?> get props => [userId, userName, role, authToken];
}
