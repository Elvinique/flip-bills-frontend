import 'package:equatable/equatable.dart';

class TravelBooking extends Equatable {
  final String bookingId;
  final String pnr; // Passenger Name Record
  final String reference;
  final String status;
  final String ticketQrData;
  final Map<String, dynamic> tripDetails;
  final DateTime createdAt;

  const TravelBooking({
    required this.bookingId,
    required this.pnr,
    required this.reference,
    required this.status,
    required this.ticketQrData,
    required this.tripDetails,
    required this.createdAt,
  });

  factory TravelBooking.fromJson(Map<String, dynamic> json) {
    return TravelBooking(
      bookingId: json['id'] as String? ?? '',
      pnr: json['pnr'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      ticketQrData: json['ticket_qr_data'] as String? ?? '',
      tripDetails: json['trip_details'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': bookingId,
      'pnr': pnr,
      'reference': reference,
      'status': status,
      'ticket_qr_data': ticketQrData,
      'trip_details': tripDetails,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [bookingId, pnr, reference, status, ticketQrData, tripDetails, createdAt];
}
