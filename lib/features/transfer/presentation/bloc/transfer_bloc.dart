import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/transfer_repository.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class TransferEvent extends Equatable {
  const TransferEvent();
  @override
  List<Object?> get props => [];
}

class TransferLoadBanks extends TransferEvent {}

class TransferResolveAccount extends TransferEvent {
  final String accountNumber;
  final String bankCode;
  const TransferResolveAccount({required this.accountNumber, required this.bankCode});
  @override
  List<Object?> get props => [accountNumber, bankCode];
}

class TransferSendBank extends TransferEvent {
  final String accountNumber;
  final String bankCode;
  final String accountName;
  final int amountKobo;
  final String narration;
  const TransferSendBank({
    required this.accountNumber,
    required this.bankCode,
    required this.accountName,
    required this.amountKobo,
    required this.narration,
  });
  @override
  List<Object?> get props => [accountNumber, bankCode, amountKobo];
}

class TransferSendWallet extends TransferEvent {
  final String recipientPhone;
  final int amountKobo;
  final String narration;
  const TransferSendWallet({
    required this.recipientPhone,
    required this.amountKobo,
    required this.narration,
  });
  @override
  List<Object?> get props => [recipientPhone, amountKobo];
}

class TransferReset extends TransferEvent {}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class TransferState extends Equatable {
  const TransferState();
  @override
  List<Object?> get props => [];
}

class TransferInitial extends TransferState {}

class TransferLoadingBanks extends TransferState {}

class TransferBanksLoaded extends TransferState {
  final List<Map<String, dynamic>> banks;
  const TransferBanksLoaded({required this.banks});
  @override
  List<Object?> get props => [banks];
}

class TransferResolvingAccount extends TransferState {}

class TransferAccountResolved extends TransferState {
  final String accountName;
  final String accountNumber;
  final String bankCode;
  final List<Map<String, dynamic>> banks;
  const TransferAccountResolved({
    required this.accountName,
    required this.accountNumber,
    required this.bankCode,
    required this.banks,
  });
  @override
  List<Object?> get props => [accountName, accountNumber, bankCode];
}

class TransferProcessing extends TransferState {}

class TransferSuccess extends TransferState {
  final String message;
  final String reference;
  const TransferSuccess({required this.message, required this.reference});
  @override
  List<Object?> get props => [message, reference];
}

class TransferFailure extends TransferState {
  final String message;
  const TransferFailure({required this.message});
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final _repo = TransferRepository();
  List<Map<String, dynamic>> _banks = [];

  TransferBloc() : super(TransferInitial()) {
    on<TransferLoadBanks>(_onLoadBanks);
    on<TransferResolveAccount>(_onResolveAccount);
    on<TransferSendBank>(_onSendBank);
    on<TransferSendWallet>(_onSendWallet);
    on<TransferReset>((_, emit) => emit(TransferInitial()));
  }

  Future<void> _onLoadBanks(
      TransferLoadBanks event, Emitter<TransferState> emit) async {
    emit(TransferLoadingBanks());
    _banks = await _repo.getBanks();
    emit(TransferBanksLoaded(banks: _banks));
  }

  Future<void> _onResolveAccount(
      TransferResolveAccount event, Emitter<TransferState> emit) async {
    emit(TransferResolvingAccount());
    final data = await _repo.resolveAccount(
      accountNumber: event.accountNumber,
      bankCode: event.bankCode,
    );
    if (data != null && data['account_name'] != null) {
      emit(TransferAccountResolved(
        accountName: data['account_name'] as String,
        accountNumber: event.accountNumber,
        bankCode: event.bankCode,
        banks: _banks,
      ));
    } else {
      emit(const TransferFailure(message: 'Could not resolve account. Check the details.'));
    }
  }

  Future<void> _onSendBank(
      TransferSendBank event, Emitter<TransferState> emit) async {
    emit(TransferProcessing());
    final result = await _repo.bankTransfer(
      accountNumber: event.accountNumber,
      bankCode: event.bankCode,
      accountName: event.accountName,
      amountKobo: event.amountKobo,
      narration: event.narration,
    );
    if (result != null && result['error'] == null) {
      final ref = result['reference'] as String? ?? result['id'] as String? ?? '';
      emit(TransferSuccess(message: 'Transfer initiated successfully', reference: ref));
    } else {
      final msg = result?['error'] as String? ?? 'Transfer failed. Please retry.';
      log('TransferBloc._onSendBank failure: $msg');
      emit(TransferFailure(message: msg));
    }
  }

  Future<void> _onSendWallet(
      TransferSendWallet event, Emitter<TransferState> emit) async {
    emit(TransferProcessing());
    final result = await _repo.walletTransfer(
      recipientPhone: event.recipientPhone,
      amountKobo: event.amountKobo,
      narration: event.narration,
    );
    if (result != null && result['error'] == null) {
      final ref = result['reference'] as String? ?? '';
      emit(TransferSuccess(message: 'Wallet transfer successful', reference: ref));
    } else {
      final msg = result?['error'] as String? ?? 'Transfer failed. Please retry.';
      emit(TransferFailure(message: msg));
    }
  }
}
