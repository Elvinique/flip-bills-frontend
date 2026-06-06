import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'checkout_state.dart';
import '../../data/repositories/transit_aggregation_repository.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class TriggerParallelSearch extends CheckoutEvent {
  final String origin;
  final String destination;
  final String departureDate;

  const TriggerParallelSearch({
    this.origin = 'Lagos',
    this.destination = 'Abuja',
    String? departureDate,
  }) : departureDate = departureDate ?? '';

  @override
  List<Object?> get props => [origin, destination, departureDate];
}

class UpdateSeatSelection extends CheckoutEvent {
  final List<int> seats;
  const UpdateSeatSelection(this.seats);

  @override
  List<Object?> get props => [seats];
}

class SelectManifest extends CheckoutEvent {
  final Map<String, dynamic> manifest;
  const SelectManifest(this.manifest);

  @override
  List<Object?> get props => [manifest];
}

/// Fired after biometric auth passes — triggers the real backend booking call.
class ConfirmBusBooking extends CheckoutEvent {
  final String passengerName;
  final String passengerPhone;
  final String password;

  const ConfirmBusBooking({
    required this.passengerName,
    required this.passengerPhone,
    required this.password,
  });

  @override
  List<Object?> get props => [passengerName, passengerPhone];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final TransitAggregationRepository _repo = TransitAggregationRepository();

  CheckoutBloc() : super(CheckoutInitial()) {
    on<TriggerParallelSearch>(_onSearch);
    on<UpdateSeatSelection>(_onSeatUpdate);
    on<SelectManifest>(_onSelectManifest);
    on<ConfirmBusBooking>(_onConfirmBooking);
  }

  Future<void> _onSearch(TriggerParallelSearch event, Emitter<CheckoutState> emit) async {
    emit(CheckoutQueryingWorkers());

    final date = event.departureDate.isNotEmpty
        ? event.departureDate
        : DateTime.now().toIso8601String().substring(0, 10);

    final manifests = await _repo.fetchParallelManifests(
      departure: event.origin,
      destination: event.destination,
      departureDate: date,
    );

    emit(CheckoutSelectionActive(
      selectedSeats: const [],
      manifests: manifests,
      // Auto-select the first (cheapest/first) manifest so there's always one ready
      selectedManifest: manifests.isNotEmpty ? manifests.first : null,
    ));
  }

  void _onSeatUpdate(UpdateSeatSelection event, Emitter<CheckoutState> emit) {
    final current = state;
    if (current is CheckoutSelectionActive) {
      emit(CheckoutSelectionActive(
        selectedSeats: event.seats,
        manifests: current.manifests,
        selectedManifest: current.selectedManifest,
      ));
    }
  }

  void _onSelectManifest(SelectManifest event, Emitter<CheckoutState> emit) {
    final current = state;
    if (current is CheckoutSelectionActive) {
      emit(CheckoutSelectionActive(
        selectedSeats: current.selectedSeats,
        manifests: current.manifests,
        selectedManifest: event.manifest,
      ));
    }
  }

  Future<void> _onConfirmBooking(ConfirmBusBooking event, Emitter<CheckoutState> emit) async {
    final current = state;
    if (current is! CheckoutSelectionActive) return;

    final manifest = current.selectedManifest;
    if (manifest == null) {
      emit(const CheckoutFailureReversal(
        message: 'No operator selected. Please search again and select a route.',
      ));
      return;
    }

    if (current.selectedSeats.isEmpty) {
      emit(const CheckoutFailureReversal(
        message: 'No seats selected. Please select at least one seat.',
      ));
      return;
    }

    emit(CheckoutProcessingLedger());

    try {
      // Book each selected seat sequentially; backend creates one booking per seat.
      // We use the first booking's response for the QR/confirmation data.
      final String departureDate = manifest['departure_date'] as String? ??
          DateTime.now().toIso8601String().substring(0, 10);

      Map<String, dynamic>? firstBooking;

      for (final seat in current.selectedSeats) {
        final result = await _repo.bookBus(
          operatorCode: manifest['operator_code'] as String,
          vehicleRef: manifest['vehicle_ref'] as String,
          seatNumber: seat.toString(),
          departureDate: departureDate,
          origin: manifest['origin'] as String,
          destination: manifest['destination'] as String,
          passengerName: event.passengerName,
          passengerPhone: event.passengerPhone,
        );

        if (result == null) {
          emit(CheckoutFailureReversal(
            message:
                'Booking failed for seat $seat. Wallet has not been charged. Please try again.',
          ));
          return;
        }

        firstBooking ??= result;
      }

      final qrData = firstBooking?['offline_qr'] as String? ??
          firstBooking?['qr_data'] as String? ??
          firstBooking?['booking_ref'] as String? ??
          'FLIP-${DateTime.now().millisecondsSinceEpoch}';

      final bookingId = firstBooking?['id'] as String? ??
          firstBooking?['booking_id'] as String? ??
          qrData;

      emit(CheckoutSuccess(
        bookingId: bookingId,
        ticketQrData: qrData,
        operatorName: manifest['operator_name'] as String? ?? manifest['operator_code'] as String,
        origin: manifest['origin'] as String,
        destination: manifest['destination'] as String,
        departureDate: departureDate,
        seats: current.selectedSeats,
      ));
    } catch (e) {
      emit(CheckoutFailureReversal(
        message: 'Booking failed: ${e.toString()}. Please try again.',
      ));
    }
  }
}
