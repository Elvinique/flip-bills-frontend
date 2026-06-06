import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/auth_repository.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String phone;
  final String password;
  const AuthLoginRequested({required this.phone, required this.password});
  @override
  List<Object?> get props => [phone, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String phone;
  final String password;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  const AuthRegisterRequested({
    required this.phone,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
  });
  @override
  List<Object?> get props => [phone, password, firstName, lastName, dateOfBirth];
}

class AuthReset extends AuthEvent {}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthLoginSuccess extends AuthState {
  final String phone;
  final String firstName;
  final String lastName;
  const AuthLoginSuccess({
    required this.phone,
    required this.firstName,
    required this.lastName,
  });
  @override
  List<Object?> get props => [phone, firstName, lastName];
}

class AuthRegisterSuccess extends AuthState {
  final String phone;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  const AuthRegisterSuccess({
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
  });
  @override
  List<Object?> get props => [phone, firstName, lastName, dateOfBirth];
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure({required this.message});
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo = AuthRepository();

  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthReset>((_, emit) => emit(AuthInitial()));
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _repo.login(phone: event.phone, password: event.password);
    if (result != null && result['data'] != null) {
      final data = result['data'] as Map?;
      final user = data?['user'] as Map? ?? data ?? {};
      emit(AuthLoginSuccess(
        phone: _toE164(event.phone),
        firstName: user['first_name']?.toString() ?? '',
        lastName: user['last_name']?.toString() ?? '',
      ));
    } else {
      final msg = result?['message'] as String? ?? 'Login failed. Check your credentials.';
      emit(AuthFailure(message: msg));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final e164 = _toE164(event.phone);

    final result = await _repo.register(
      phone: e164,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
      dateOfBirth: event.dateOfBirth,
    );

    if (result['success'] == true || result['success'].toString() == 'true') {
      // Auto-login to get JWT into memory
      final loginResult = await _repo.login(phone: e164, password: event.password);
      if (loginResult != null && loginResult['data'] != null) {
        log('Auto-login after register succeeded');
      } else {
        log('Auto-login after register failed');
      }
      emit(AuthRegisterSuccess(
        phone: e164,
        firstName: event.firstName,
        lastName: event.lastName,
        dateOfBirth: event.dateOfBirth,
      ));
    } else {
      final msg = result['message'] as String? ?? 'Registration failed. Try again.';
      emit(AuthFailure(message: msg));
    }
  }

  String _toE164(String phone) {
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0')) return '+234${phone.substring(1)}';
    return '+234$phone';
  }
}
