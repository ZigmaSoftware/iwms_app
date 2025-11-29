import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// App starting / checking persistence
class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

/// Any ongoing login or async process
class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// Unified authenticated state
class AuthStateAuthenticated extends AuthState {
  final String userName;
  final String role; // citizen, operator, driver, admin

  const AuthStateAuthenticated({
    required this.userName,
    required this.role,
  });

  @override
  List<Object?> get props => [userName, role];
}

/// Logged out
class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

/// Login failure
class AuthStateFailure extends AuthState {
  final String message;

  const AuthStateFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
