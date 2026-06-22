import 'package:equatable/equatable.dart';

class Flight extends Equatable {
  final String flightId;
  final String airline;
  final String originCode;
  final String destinationCode;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int priceKobo;
  final String cabinClass;

  const Flight({
    required this.flightId,
    required this.airline,
    required this.originCode,
    required this.destinationCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.priceKobo,
    required this.cabinClass,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      flightId: json['flight_id'] as String? ?? '',
      airline: json['airline'] as String? ?? 'Unknown',
      originCode: json['origin_code'] as String? ?? '',
      destinationCode: json['destination_code'] as String? ?? '',
      departureTime: json['departure_time'] != null 
          ? DateTime.parse(json['departure_time'] as String) 
          : DateTime.now(),
      arrivalTime: json['arrival_time'] != null 
          ? DateTime.parse(json['arrival_time'] as String) 
          : DateTime.now(),
      priceKobo: json['price_kobo'] as int? ?? 0,
      cabinClass: json['cabin_class'] as String? ?? 'Economy',
    );
  }

  @override
  List<Object?> get props => [
        flightId,
        airline,
        originCode,
        destinationCode,
        departureTime,
        arrivalTime,
        priceKobo,
        cabinClass,
      ];
}
