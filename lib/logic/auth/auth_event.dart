abstract class AuthEvent {}

class AuthStatusChecked extends AuthEvent {}

class AuthCitizenLoginRequested extends AuthEvent {
  final String username;
  final String password;

  AuthCitizenLoginRequested({required this.username, required this.password});
}

class AuthCitizenRegisterRequested extends AuthEvent {
  final String fullName;

  AuthCitizenRegisterRequested({required this.fullName});
}

class AuthLogoutRequested extends AuthEvent {}

class AuthOperatorLoginRequested extends AuthEvent {
  final String operatorId;
  final String userName;

  AuthOperatorLoginRequested({required this.operatorId, required this.userName});
}
