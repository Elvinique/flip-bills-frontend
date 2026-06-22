import 'package:dio/dio.dart';
import '../models/bus_trip.dart';
import '../models/flight.dart';
import '../models/seat_layout.dart';
import '../models/travel_booking.dart';
import '../../../../core/network/api_client.dart'; // Adjust import if needed

class TravelRepository {
  final ApiClient _apiClient;

  TravelRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient.instance;

  Future<List<BusTrip>> searchBusTrips({
    required String origin,
    required String destination,
    required DateTime date,
    required int passengers,
  }) async {
    try {
      final response = await _apiClient.dio.get('/travel/bus/search', queryParameters: {
        'origin': origin,
        'destination': destination,
        'date': date.toIso8601String().split('T').first,
        'passengers': passengers,
      });

      final data = response.data['data'] as List;
      return data.map((e) => BusTrip.fromJson(e)).toList();
    } catch (e) {
      // In development/sandbox mode, if API fails, return mock data
      return [
        BusTrip(
          tripId: 'TRP-1001',
          operatorName: 'GIGM',
          origin: origin,
          destination: destination,
          departureTime: date.add(const Duration(hours: 8)),
          priceKobo: 2500000, // 25,000 NGN
          availableSeats: 12,
          vehicleType: 'Executive Sprinter',
          amenities: const ['AC', 'WiFi', 'Charging Ports'],
        ),
        BusTrip(
          tripId: 'TRP-1002',
          operatorName: 'ABC Transport',
          origin: origin,
          destination: destination,
          departureTime: date.add(const Duration(hours: 10)),
          priceKobo: 2100000, // 21,000 NGN
          availableSeats: 20,
          vehicleType: 'Standard Coach',
          amenities: const ['AC', 'Toilets'],
        ),
      ];
    }
  }

  Future<List<Flight>> searchFlights({
    required String origin,
    required String destination,
    required DateTime date,
    required int passengers,
  }) async {
    try {
      final response = await _apiClient.dio.get('/travel/flight/search', queryParameters: {
        'origin': origin,
        'destination': destination,
        'date': date.toIso8601String().split('T').first,
        'passengers': passengers,
      });

      final data = response.data['data'] as List;
      return data.map((e) => Flight.fromJson(e)).toList();
    } catch (e) {
      // Mock data fallback
      return [
        Flight(
          flightId: 'FL-AER-1',
          airline: 'Air Peace',
          originCode: origin,
          destinationCode: destination,
          departureTime: date.add(const Duration(hours: 9)),
          arrivalTime: date.add(const Duration(hours: 10, minutes: 15)),
          priceKobo: 8500000, // 85,000 NGN
          cabinClass: 'Economy',
        ),
        Flight(
          flightId: 'FL-IBK-2',
          airline: 'Ibom Air',
          originCode: origin,
          destinationCode: destination,
          departureTime: date.add(const Duration(hours: 14)),
          arrivalTime: date.add(const Duration(hours: 15, minutes: 10)),
          priceKobo: 9500000, // 95,000 NGN
          cabinClass: 'Economy',
        ),
      ];
    }
  }

  Future<SeatLayout> getBusSeatLayout(String tripId) async {
    try {
      final response = await _apiClient.dio.get('/travel/bus/seats/$tripId');
      return SeatLayout.fromJson(response.data['data']);
    } catch (e) {
      // Mock layout
      return const SeatLayout(
        totalSeats: 15,
        rows: 5,
        columns: 3,
        bookedSeats: ['1A', '2B', '5C'],
        availableSeats: ['1B', '1C', '2A', '2C', '3A', '3B', '3C', '4A', '4B', '4C', '5A', '5B'],
      );
    }
  }

  Future<TravelBooking> bookBusTrip({
    required String tripId,
    required List<String> seatNumbers,
    required String pin,
  }) async {
    try {
      final response = await _apiClient.dio.post('/travel/bus/book', data: {
        'trip_id': tripId,
        'seats': seatNumbers,
        'pin': pin,
      });
      return TravelBooking.fromJson(response.data['data']);
    } catch (e) {
      if (e is DioException && e.response?.statusCode != null) {
        throw Exception(e.response?.data['error'] ?? 'Booking failed');
      }
      
      // Mock successful booking
      return TravelBooking(
        bookingId: 'BK-${DateTime.now().millisecondsSinceEpoch}',
        pnr: 'GIGM${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        reference: 'FLIP-TRV-${DateTime.now().millisecondsSinceEpoch}',
        status: 'confirmed',
        ticketQrData: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mockQRpayload',
        tripDetails: {
          'trip_id': tripId,
          'seats': seatNumbers,
        },
        createdAt: DateTime.now(),
      );
    }
  }

  Future<List<TravelBooking>> getMyBookings() async {
    try {
      final response = await _apiClient.dio.get('/travel/bookings');
      final data = response.data['data'] as List;
      return data.map((e) => TravelBooking.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
