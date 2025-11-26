// lib/logic/auth/auth_event.dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCitizenLoginRequested extends AuthEvent {
  final String username;
  final String password;
  // final String? userType;

  const AuthCitizenLoginRequested({
    required this.username,
    required this.password,
    // this.userType,
  });

  @override
  List<Object?> get props => [username, password];
}

class AuthCitizenRegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;

  const AuthCitizenRegisterRequested({
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [fullName, email, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthStatusChecked extends AuthEvent {}
class AuthOperatorLoginRequested extends AuthEvent {
  final String userName;
  final String operatorId;

  const AuthOperatorLoginRequested({
    required this.userName,
    required this.operatorId,
  });
}
