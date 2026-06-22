import 'package:equatable/equatable.dart';
import '../../data/models/bus_trip.dart';
import '../../data/models/flight.dart';
import '../../data/models/seat_layout.dart';
import '../../data/models/travel_booking.dart';

abstract class TravelState extends Equatable {
  const TravelState();

  @override
  List<Object?> get props => [];
}

class TravelInitial extends TravelState {}

class TravelSearchLoading extends TravelState {}

class TravelBusSearchLoaded extends TravelState {
  final List<BusTrip> trips;

  const TravelBusSearchLoaded(this.trips);

  @override
  List<Object?> get props => [trips];
}

class TravelFlightSearchLoaded extends TravelState {
  final List<Flight> flights;

  const TravelFlightSearchLoaded(this.flights);

  @override
  List<Object?> get props => [flights];
}

class TravelSeatLayoutLoading extends TravelState {}

class TravelSeatLayoutLoaded extends TravelState {
  final SeatLayout layout;
  final List<String> selectedSeats;

  const TravelSeatLayoutLoaded({
    required this.layout,
    this.selectedSeats = const [],
  });

  TravelSeatLayoutLoaded copyWith({
    SeatLayout? layout,
    List<String>? selectedSeats,
  }) {
    return TravelSeatLayoutLoaded(
      layout: layout ?? this.layout,
      selectedSeats: selectedSeats ?? this.selectedSeats,
    );
  }

  @override
  List<Object?> get props => [layout, selectedSeats];
}

class TravelBookingProcessing extends TravelState {}

class TravelBookingSuccess extends TravelState {
  final TravelBooking booking;

  const TravelBookingSuccess(this.booking);

  @override
  List<Object?> get props => [booking];
}

class TravelMyBookingsLoaded extends TravelState {
  final List<TravelBooking> bookings;

  const TravelMyBookingsLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class TravelError extends TravelState {
  final String message;

  const TravelError(this.message);

  @override
  List<Object?> get props => [message];
}
