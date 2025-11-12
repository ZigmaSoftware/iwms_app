// lib/logic/auth/auth_event.dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCitizenLoginRequested extends AuthEvent {
  final String? phone;
  final String? fullName;

  const AuthCitizenLoginRequested({
    this.phone,
    this.fullName,
  });

  @override
  List<Object?> get props => [phone, fullName];
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
