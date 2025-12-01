import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String userId;
  final String userName;
  final String role;
  final String? authToken;
  final String? emp_id;
  final String? customer_id;
  const UserModel({
    required this.userId,
    required this.userName,
    required this.role,
    this.authToken,
    this.emp_id,
    this.customer_id,
  });
  factory UserModel.fromApi(Map<String, dynamic> json) {
    return UserModel(
      userId: json["unique_id"]?.toString() ?? "",
      userName: json["name"]?.toString() ?? "",
      role: json["role"]?.toString().toLowerCase() ?? "citizen",
      authToken: json["access_token"]?.toString(),
      emp_id: json["emp_id"]?.toString(),
      customer_id: json["customer_id"]?.toString(),
    );
  }
  @override
  List<Object?> get props =>
      [userId, userName, role, authToken, emp_id, customer_id];
}
