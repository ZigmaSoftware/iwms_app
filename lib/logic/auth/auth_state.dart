// lib/logic/auth/auth_state.dart
import 'package:equatable/equatable.dart';

enum UserRole {
  unknown,
  unauthenticated,
  citizen,
  operator,
  driver,
  supervisor,
  engineer,
  admin,
}

class AuthState extends Equatable {
  final UserRole role;
  final String? userName;

  const AuthState({this.role = UserRole.unknown, this.userName});

  @override
  List<Object?> get props => [role, userName];
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial() : super(role: UserRole.unknown);
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading() : super(role: UserRole.unknown);
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated() : super(role: UserRole.unauthenticated);
}

abstract class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated({required super.role, required String super.userName});
}

class AuthStateAuthenticatedCitizen extends AuthStateAuthenticated {
  const AuthStateAuthenticatedCitizen({required super.userName})
      : super(role: UserRole.citizen);
}

class AuthStateAuthenticatedOperator extends AuthStateAuthenticated {
  const AuthStateAuthenticatedOperator({required super.userName})
      : super(role: UserRole.operator);
}

class AuthStateAuthenticatedDriver extends AuthStateAuthenticated {
  const AuthStateAuthenticatedDriver({required super.userName})
      : super(role: UserRole.driver);
}

class AuthStateAuthenticatedAdmin extends AuthStateAuthenticated {
  const AuthStateAuthenticatedAdmin({required super.userName})
      : super(role: UserRole.admin);
}

class AuthStateFailure extends AuthState {
  final String message;

  const AuthStateFailure({required this.message}) : super(role: UserRole.unknown);

  @override
  List<Object?> get props => [role, userName, message];
}
