import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'checkout_state.dart';
import '../../data/repositories/transit_aggregation_repository.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class TriggerParallelSearch extends CheckoutEvent {}

class UpdateSeatSelection extends CheckoutEvent {
  final List<int> seats;
  const UpdateSeatSelection(this.seats);

  @override
  List<Object?> get props => [seats];
}

class ConfirmBiometricCheckout extends CheckoutEvent {
  final double amount;
  const ConfirmBiometricCheckout(this.amount);

  @override
  List<Object?> get props => [amount];
}

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final TransitAggregationRepository _aggregationRepository = TransitAggregationRepository();

  CheckoutBloc() : super(CheckoutInitial()) {
    on<TriggerParallelSearch>(_onSearch);
    on<UpdateSeatSelection>(_onSeatUpdate);
    on<ConfirmBiometricCheckout>(_onConfirmCheckout);
  }

  Future<void> _onSearch(TriggerParallelSearch event, Emitter<CheckoutState> emit) async {
    emit(CheckoutQueryingWorkers());
    
    final List<Map<String, dynamic>> multiProviderManifests = 
        await _aggregationRepository.fetchParallelManifests(
          departure: "Lagos", 
          destination: "Abuja",
        );
    
    emit(CheckoutSelectionActive(
      selectedSeats: const [],
      manifests: multiProviderManifests,
    ));
  }

  void _onSeatUpdate(UpdateSeatSelection event, Emitter<CheckoutState> emit) {
    final currentState = state;
    List<Map<String, dynamic>> existingManifests = const [];
    
    if (currentState is CheckoutSelectionActive) {
      existingManifests = currentState.manifests;
    }

    emit(CheckoutSelectionActive(
      selectedSeats: event.seats,
      manifests: existingManifests,
    ));
  }

  Future<void> _onConfirmCheckout(ConfirmBiometricCheckout event, Emitter<CheckoutState> emit) async {
    // Intercepts our specific simulation amount (-1.0) to instantly show the drop shield layout
    if (event.amount == -1.0) {
      emit(const CheckoutFailureReversal(
        message: "SIMULATED ERROR: Highway cell tower connection dropped. Reversing wallet lock and enabling local enclave pass."
      ));
      return;
    }

    emit(CheckoutProcessingLedger());
    try {
      await Future.delayed(const Duration(seconds: 2)).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw TimeoutException("Biller Endpoint Timeout"),
      );
      emit(const CheckoutSuccess(ticketQrData: "BYE_BYE_BILL_SECURE_HASH_2026"));
    } catch (error) {
      emit(const CheckoutFailureReversal(
        message: "Primary route timed out. Wallet reversal executed. Swapping route from Interswitch to Flutterwave."
      ));
    }
  }
}