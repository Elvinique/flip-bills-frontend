import 'package:equatable/equatable.dart';

abstract class TravelEvent extends Equatable {
  const TravelEvent();

  @override
  List<Object?> get props => [];
}

class TravelSearchBusTrips extends TravelEvent {
  final String origin;
  final String destination;
  final DateTime date;
  final int passengers;

  const TravelSearchBusTrips({
    required this.origin,
    required this.destination,
    required this.date,
    required this.passengers,
  });

  @override
  List<Object?> get props => [origin, destination, date, passengers];
}

class TravelSearchFlights extends TravelEvent {
  final String origin;
  final String destination;
  final DateTime date;
  final int passengers;

  const TravelSearchFlights({
    required this.origin,
    required this.destination,
    required this.date,
    required this.passengers,
  });

  @override
  List<Object?> get props => [origin, destination, date, passengers];
}

class TravelFetchSeatLayout extends TravelEvent {
  final String tripId;

  const TravelFetchSeatLayout(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class TravelSelectSeats extends TravelEvent {
  final List<String> seatNumbers;

  const TravelSelectSeats(this.seatNumbers);

  @override
  List<Object?> get props => [seatNumbers];
}

class TravelBookBusTrip extends TravelEvent {
  final String tripId;
  final List<String> seatNumbers;
  final String pin;

  const TravelBookBusTrip({
    required this.tripId,
    required this.seatNumbers,
    required this.pin,
  });

  @override
  List<Object?> get props => [tripId, seatNumbers, pin];
}

class TravelFetchMyBookings extends TravelEvent {}
