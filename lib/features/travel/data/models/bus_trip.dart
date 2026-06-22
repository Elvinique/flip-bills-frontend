import 'package:equatable/equatable.dart';

class BusTrip extends Equatable {
  final String tripId;
  final String operatorName; // e.g., "GIGM" or "ABC"
  final String origin;
  final String destination;
  final DateTime departureTime;
  final int priceKobo;
  final int availableSeats;
  final String vehicleType;
  final List<String> amenities;

  const BusTrip({
    required this.tripId,
    required this.operatorName,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.priceKobo,
    required this.availableSeats,
    required this.vehicleType,
    required this.amenities,
  });

  factory BusTrip.fromJson(Map<String, dynamic> json) {
    return BusTrip(
      tripId: json['trip_id'] as String? ?? '',
      operatorName: json['operator_name'] as String? ?? 'Unknown',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      departureTime: json['departure_time'] != null 
          ? DateTime.parse(json['departure_time'] as String) 
          : DateTime.now(),
      priceKobo: json['price_kobo'] as int? ?? 0,
      availableSeats: json['available_seats'] as int? ?? 0,
      vehicleType: json['vehicle_type'] as String? ?? 'Standard',
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [
        tripId,
        operatorName,
        origin,
        destination,
        departureTime,
        priceKobo,
        availableSeats,
        vehicleType,
        amenities,
      ];
}
