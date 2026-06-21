import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/wallet_repository.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

class WalletLoadRequested extends WalletEvent {}

class WalletTransactionsRequested extends WalletEvent {
  final int page;
  final int limit;
  const WalletTransactionsRequested({this.page = 1, this.limit = 20});
  @override
  List<Object?> get props => [page, limit];
}

class WalletFundingInitialized extends WalletEvent {
  final int amountKobo;
  final String provider;
  const WalletFundingInitialized({required this.amountKobo, required this.provider});
  @override
  List<Object?> get props => [amountKobo, provider];
}

class WalletRefreshRequested extends WalletEvent {}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class WalletState extends Equatable {
  const WalletState();
  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final double balanceNgn;
  final double dailySpentNgn;
  final double dailyLimitNgn;
  final int loyaltyPoints;
  final String tier;

  const WalletLoaded({
    required this.balanceNgn,
    required this.dailySpentNgn,
    required this.dailyLimitNgn,
    required this.loyaltyPoints,
    required this.tier,
  });

  @override
  List<Object?> get props => [balanceNgn, dailySpentNgn, dailyLimitNgn, loyaltyPoints, tier];
}

class WalletTransactionsLoaded extends WalletState {
  final double balanceNgn;
  final List<Map<String, dynamic>> transactions;
  final bool hasMore;

  const WalletTransactionsLoaded({
    required this.balanceNgn,
    required this.transactions,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [balanceNgn, transactions, hasMore];
}

class WalletFundingReady extends WalletState {
  final String paymentLink;
  final String reference;

  const WalletFundingReady({required this.paymentLink, required this.reference});

  @override
  List<Object?> get props => [paymentLink, reference];
}

class WalletError extends WalletState {
  final String message;
  const WalletError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository _repo = WalletRepository();

  WalletBloc() : super(WalletInitial()) {
    on<WalletLoadRequested>(_onLoad);
    on<WalletTransactionsRequested>(_onLoadTransactions);
    on<WalletFundingInitialized>(_onInitializeFunding);
    on<WalletRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(WalletLoadRequested event, Emitter<WalletState> emit) async {
    emit(WalletLoading());
    final data = await _repo.getBalance();
    if (data != null) {
      emit(WalletLoaded(
        balanceNgn: (data['balance_ngn'] as num?)?.toDouble() ?? 0.0,
        dailySpentNgn: (data['daily_spent_ngn'] as num?)?.toDouble() ?? 0.0,
        dailyLimitNgn: (data['daily_limit_ngn'] as num?)?.toDouble() ?? 50000.0,
        loyaltyPoints: (data['loyalty_points'] as num?)?.toInt() ?? 0,
        tier: data['tier'] as String? ?? 'basic',
      ));
    } else {
      emit(const WalletError(message: 'Could not load wallet. Check your connection.'));
    }
  }

  Future<void> _onRefresh(WalletRefreshRequested event, Emitter<WalletState> emit) async {
    final data = await _repo.getBalance();
    if (data != null) {
      emit(WalletLoaded(
        balanceNgn: (data['balance_ngn'] as num?)?.toDouble() ?? 0.0,
        dailySpentNgn: (data['daily_spent_ngn'] as num?)?.toDouble() ?? 0.0,
        dailyLimitNgn: (data['daily_limit_ngn'] as num?)?.toDouble() ?? 50000.0,
        loyaltyPoints: (data['loyalty_points'] as num?)?.toInt() ?? 0,
        tier: data['tier'] as String? ?? 'basic',
      ));
    }
  }

  Future<void> _onLoadTransactions(
      WalletTransactionsRequested event, Emitter<WalletState> emit) async {
    emit(WalletLoading());
    final balanceData = await _repo.getBalance();
    final txData = await _repo.getTransactions(page: event.page, limit: event.limit);

    final balance = (balanceData?['balance_ngn'] as num?)?.toDouble() ?? 0.0;
    final txList = txData?['transactions'] as List<dynamic>? ?? [];
    final total = txData?['total'] as int? ?? 0;

    emit(WalletTransactionsLoaded(
      balanceNgn: balance,
      transactions: txList.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      hasMore: txList.length < total,
    ));
  }

  Future<void> _onInitializeFunding(
      WalletFundingInitialized event, Emitter<WalletState> emit) async {
    emit(WalletLoading());
    final data = await _repo.initializeFunding(
      amountKobo: event.amountKobo,
      provider: event.provider,
    );
    if (data != null && data['checkout_url'] != null) {
      emit(WalletFundingReady(
        paymentLink: data['checkout_url'] as String,
        reference: data['reference'] as String? ?? '',
      ));
    } else {
      emit(const WalletError(message: 'Failed to initialize funding. Please try again.'));
    }
  }
}
