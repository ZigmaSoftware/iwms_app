// lib/logic/auth/auth_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iwms_citizen_app/data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

const String _demoCitizenName = 'Citizen Demo';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final Future<void> initialization;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        initialization = authRepository.initialize(),
        super(const AuthStateInitial()) {
    on<AuthStatusChecked>(_onStatusChecked);
    on<AuthCitizenLoginRequested>(_onCitizenLoginRequested);
    on<AuthCitizenRegisterRequested>(_onCitizenRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthOperatorLoginRequested>(_onOperatorLoginRequested);


    initialization.then((_) {
      add(AuthStatusChecked());
    });
  }

  Future<void> _onStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthStateInitial());
    final user = await _authRepository.getAuthenticatedUser();

    if (user != null) {
      switch (user.role) {
        case 'citizen':
          emit(AuthStateAuthenticatedCitizen(userName: user.userName));
          break;
        case 'operator':
          emit(AuthStateAuthenticatedOperator(userName: user.userName));
          break;
        default:
          await _authRepository.logout();
          emit(const AuthStateUnauthenticated());
          break;
      }
    } else {
      emit(const AuthStateUnauthenticated());
    }
  }

  // Future<void> _onCitizenLoginRequested(
  //   AuthCitizenLoginRequested event,
  //   Emitter<AuthState> emit,
  // ) async {
  //   emit(const AuthStateLoading());
  //   try {
  //     final user = await _authRepository.loginCitizen(
  //       username: event.username,
  //       password: event.password,
  //       // userType: event.userType,
  //     );
  //     await _authRepository.saveUser(user);
  //     emit(AuthStateAuthenticatedCitizen(userName: user.userName));
  //   } on AuthRepositoryException catch (error) {
  //     emit(AuthStateFailure(message: error.message));
  //     emit(const AuthStateUnauthenticated());
  //   } catch (_) {
  //     emit(const AuthStateFailure(message: 'Unable to login. Please try again.'));
  //     emit(const AuthStateUnauthenticated());
  //   }
  // }
Future<void> _onCitizenLoginRequested(
  AuthCitizenLoginRequested event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthStateLoading());

  try {
    final user = await _authRepository.loginCitizen(
      username: event.username,
      password: event.password,
    );

    switch (user.role) {
  case "customer":
  case "citizen":
    emit(AuthStateAuthenticatedCitizen(userName: user.userName));
    break;

  case "operator":
    emit(AuthStateAuthenticatedOperator(userName: user.userName));
    break;

  case "driver":
    emit(AuthStateAuthenticatedDriver(userName: user.userName));
    break;

  case "admin":
    emit(AuthStateAuthenticatedAdmin(userName: user.userName));
    break;

  default:
    emit(const AuthStateFailure(message: "Unknown user role"));
    emit(const AuthStateUnauthenticated());
    break;
}

  } 
  catch (e) {
    emit(AuthStateFailure(message: e.toString()));
    emit(const AuthStateUnauthenticated());
  }
}

  Future<void> _onCitizenRegisterRequested(
    AuthCitizenRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthStateLoading());
    final trimmedName = event.fullName.trim();
    final userName = trimmedName.isNotEmpty ? trimmedName : _demoCitizenName;
    final user = UserModel(
      userId: 'CUS-REG-${userName.replaceAll(' ', '').toUpperCase()}',
      userName: userName,
      role: 'citizen',
      authToken: 'demo-token-citizen',
    );
    await _authRepository.saveUser(user);
    emit(AuthStateAuthenticatedCitizen(userName: user.userName));
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthStateUnauthenticated());
  }
Future<void> _onOperatorLoginRequested(
  AuthOperatorLoginRequested event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthStateLoading());

  final user = UserModel(
    userId: event.operatorId,
    userName: event.userName,
    role: 'operator',
    authToken: 'operator-token',
  );

  await _authRepository.saveUser(user);

  emit(AuthStateAuthenticatedOperator(userName: user.userName));
}

}
