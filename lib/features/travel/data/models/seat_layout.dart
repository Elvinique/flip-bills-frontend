import 'package:equatable/equatable.dart';

class SeatLayout extends Equatable {
  final int totalSeats;
  final int rows;
  final int columns;
  final List<String> bookedSeats;
  final List<String> availableSeats;

  const SeatLayout({
    required this.totalSeats,
    required this.rows,
    required this.columns,
    required this.bookedSeats,
    required this.availableSeats,
  });

  factory SeatLayout.fromJson(Map<String, dynamic> json) {
    return SeatLayout(
      totalSeats: json['total_seats'] as int? ?? 0,
      rows: json['rows'] as int? ?? 0,
      columns: json['columns'] as int? ?? 0,
      bookedSeats: (json['booked_seats'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      availableSeats: (json['available_seats'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [totalSeats, rows, columns, bookedSeats, availableSeats];
}
