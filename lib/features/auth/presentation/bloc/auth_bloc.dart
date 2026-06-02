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
  const AuthRegisterRequested({
    required this.phone,
    required this.password,
    required this.firstName,
    required this.lastName,
  });
  @override
  List<Object?> get props => [phone, password, firstName, lastName];
}

class AuthVerifyOTPRequested extends AuthEvent {
  final String phone;
  final String otp;
  const AuthVerifyOTPRequested({required this.phone, required this.otp});
  @override
  List<Object?> get props => [phone, otp];
}

class AuthResendOTPRequested extends AuthEvent {
  final String phone;
  const AuthResendOTPRequested({required this.phone});
  @override
  List<Object?> get props => [phone];
}

class AuthSetPINRequested extends AuthEvent {
  final String pin;
  final String confirmPin;
  /// Phone and password passed directly from registration — no storage needed.
  final String phone;
  final String password;
  const AuthSetPINRequested({
    required this.pin,
    required this.confirmPin,
    required this.phone,
    required this.password,
  });
  @override
  List<Object?> get props => [pin, confirmPin, phone, password];
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
  const AuthLoginSuccess({required this.phone});
  @override
  List<Object?> get props => [phone];
}

/// Carries phone + password so PINSetupPage can receive them and pass
/// them back in AuthSetPINRequested without touching storage.
class AuthRegisterSuccess extends AuthState {
  final String phone;
  final String password;
  const AuthRegisterSuccess({required this.phone, required this.password});
  @override
  List<Object?> get props => [phone, password];
}

class AuthOTPVerified extends AuthState {}
class AuthOTPResent extends AuthState {}
class AuthPINSet extends AuthState {}

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
    on<AuthVerifyOTPRequested>(_onVerifyOTP);
    on<AuthResendOTPRequested>(_onResendOTP);
    on<AuthSetPINRequested>(_onSetPIN);
    on<AuthReset>((_, emit) => emit(AuthInitial()));
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _repo.login(phone: event.phone, password: event.password);
    if (result != null && result['data'] != null) {
      final e164 = _toE164(event.phone);
      emit(AuthLoginSuccess(phone: e164));
    } else {
      final msg = result?['message'] ?? 'Login failed. Check your credentials.';
      emit(AuthFailure(message: msg));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final e164 = _toE164(event.phone);

    final result = await _repo.register(
      phone: event.phone,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
    );

    if (result != null && result['success'] == true) {
      // Auto-login immediately so the JWT is in memory for set-pin
      final loginResult = await _repo.login(phone: event.phone, password: event.password);
      if (loginResult != null && loginResult['data'] != null) {
        log('Auto-login after register succeeded — token in memory');
      } else {
        log('Auto-login after register failed — PIN will use phone fallback');
      }
      // Always proceed to PIN setup; pass credentials directly
      emit(AuthRegisterSuccess(phone: e164, password: event.password));
    } else {
      final msg = result?['message'] ?? 'Registration failed. Try again.';
      emit(AuthFailure(message: msg));
    }
  }

  Future<void> _onVerifyOTP(AuthVerifyOTPRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final ok = await _repo.verifyPhone(phone: event.phone, otp: event.otp);
    if (ok) {
      emit(AuthOTPVerified());
    } else {
      emit(const AuthFailure(message: 'Invalid OTP. Please try again.'));
    }
  }

  Future<void> _onResendOTP(AuthResendOTPRequested event, Emitter<AuthState> emit) async {
    final ok = await _repo.resendOTP(event.phone);
    if (ok) emit(AuthOTPResent());
  }

  Future<void> _onSetPIN(AuthSetPINRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    log('SetPIN — phone=${event.phone}');
    final ok = await _repo.setPin(
      pin: event.pin,
      confirmPin: event.confirmPin,
      phone: event.phone,
      password: event.password,
    );
    if (ok) {
      emit(AuthPINSet());
    } else {
      emit(const AuthFailure(message: 'Failed to set PIN. Please try again.'));
    }
  }

  String _toE164(String phone) {
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0')) return '+234${phone.substring(1)}';
    return '+234$phone';
  }
}
