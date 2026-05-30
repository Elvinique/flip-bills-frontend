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
  const AuthSetPINRequested({required this.pin, required this.confirmPin});
  @override
  List<Object?> get props => [pin, confirmPin];
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

class AuthRegisterSuccess extends AuthState {
  final String phone;
  const AuthRegisterSuccess({required this.phone});
  @override
  List<Object?> get props => [phone];
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
      emit(AuthLoginSuccess(phone: event.phone));
    } else {
      final msg = result?['message'] ?? 'Login failed. Check your credentials.';
      emit(AuthFailure(message: msg));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _repo.register(
      phone: event.phone,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
    );
    if (result != null) {
      emit(AuthRegisterSuccess(phone: event.phone));
    } else {
      emit(const AuthFailure(message: 'Registration failed. Try again.'));
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
    final ok = await _repo.setPin(pin: event.pin, confirmPin: event.confirmPin);
    if (ok) {
      emit(AuthPINSet());
    } else {
      emit(const AuthFailure(message: 'Failed to set PIN. Please try again.'));
    }
  }
}
