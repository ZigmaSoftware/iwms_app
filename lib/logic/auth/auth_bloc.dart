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
        default:
          await _authRepository.logout();
          emit(const AuthStateUnauthenticated());
          break;
      }
    } else {
      emit(const AuthStateUnauthenticated());
    }
  }

  Future<void> _onCitizenLoginRequested(
    AuthCitizenLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthStateLoading());
    final trimmedName = (event.fullName ?? '').trim();
    final displayName = trimmedName.isNotEmpty
        ? trimmedName
        : (event.phone?.trim().isNotEmpty == true
            ? 'Citizen ${event.phone}'
            : _demoCitizenName);
    final user = UserModel(
      userId: 'CUS-${displayName.replaceAll(' ', '').toUpperCase()}',
      userName: displayName,
      role: 'citizen',
      authToken: 'demo-token-citizen',
    );
    await _authRepository.saveUser(user);
    emit(AuthStateAuthenticatedCitizen(userName: user.userName));
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

}
