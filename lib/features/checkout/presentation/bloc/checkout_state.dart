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
  final List<Map<String, dynamic>> manifests;
  // Tracks which manifest row the user picked so the bloc can book it
  final Map<String, dynamic>? selectedManifest;

  const CheckoutSelectionActive({
    required this.selectedSeats,
    required this.manifests,
    this.selectedManifest,
  });

  @override
  List<Object?> get props => [selectedSeats, manifests, selectedManifest];
}

class CheckoutProcessingLedger extends CheckoutState {}

class CheckoutSuccess extends CheckoutState {
  final String bookingId;
  final String ticketQrData;
  final String operatorName;
  final String origin;
  final String destination;
  final String departureDate;
  final List<int> seats;

  const CheckoutSuccess({
    required this.bookingId,
    required this.ticketQrData,
    required this.operatorName,
    required this.origin,
    required this.destination,
    required this.departureDate,
    required this.seats,
  });

  @override
  List<Object?> get props => [bookingId, ticketQrData];
}

class CheckoutFailureReversal extends CheckoutState {
  final String message;
  const CheckoutFailureReversal({required this.message});

  @override
  List<Object?> get props => [message];
}
