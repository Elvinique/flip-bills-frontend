import 'package:equatable/equatable.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();
  
  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {}

class CheckoutQueryingWorkers extends CheckoutState {}

class CheckoutSelectionActive extends CheckoutState {
  final List<int> selectedSeats;
  final List<Map<String, dynamic>> manifests; // Registered network inventory collection

  const CheckoutSelectionActive({
    required this.selectedSeats,
    required this.manifests, // FIXED: Declared as an absolute required named field
  });

  @override
  List<Object?> get props => [selectedSeats, manifests];
}

class CheckoutProcessingLedger extends CheckoutState {}

class CheckoutSuccess extends CheckoutState {
  final String ticketQrData;
  const CheckoutSuccess({required this.ticketQrData});

  @override
  List<Object?> get props => [ticketQrData];
}

class CheckoutFailureReversal extends CheckoutState {
  final String message;
  const CheckoutFailureReversal({required this.message});

  @override
  List<Object?> get props => [message];
}