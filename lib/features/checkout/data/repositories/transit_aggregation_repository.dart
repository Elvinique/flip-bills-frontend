import 'dart:developer';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class TransitAggregationRepository {
  final Dio _networkWorker = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> fetchParallelManifests({
    required String departure,
    required String destination,
    required String departureDate,
  }) async {
    try {
      final Response response = await _networkWorker.get(
        '/api/v1/travel/bus/search',
        queryParameters: {
          'origin': departure,
          'destination': destination,
          'departure_date': departureDate,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
        if (responseData is List) {
          return List<Map<String, dynamic>>.from(responseData);
        }
      }
      return _getFallbackProfiles();
    } catch (e) {
      log('Bus search failed, using sandbox data: $e');
      return _getFallbackProfiles();
    }
  }

  Future<bool> purchaseAirtime({
    required String phone,
    required int amountKobo,
    required String network,
  }) async {
    try {
      final response = await _networkWorker.post(
        '/api/v1/vas/airtime',
        data: {
          'phone': phone,
          'amount': amountKobo,
          'network': network,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      log('Airtime purchase error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> payElectricity({
    required String meterNumber,
    required int amountKobo,
    required String disco,
    String meterType = 'prepaid',
  }) async {
    try {
      final response = await _networkWorker.post(
        '/api/v1/vas/electricity',
        data: {
          'meter_number': meterNumber,
          'disco': disco,
          'amount': amountKobo,
          'meter_type': meterType,
        },
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e) {
      log('Electricity payment error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> bookBus({
    required String operatorCode,
    required String vehicleRef,
    required String seatNumber,
    required String departureDate,
    required String origin,
    required String destination,
    required String passengerName,
    required String passengerPhone,
  }) async {
    try {
      final response = await _networkWorker.post(
        '/api/v1/travel/bus/book',
        data: {
          'operator_code': operatorCode,
          'vehicle_ref': vehicleRef,
          'seat_number': seatNumber,
          'departure_date': departureDate,
          'origin': origin,
          'destination': destination,
          'passenger': {
            'full_name': passengerName,
            'phone': passengerPhone,
          },
        },
      );
      if (response.statusCode == 201 && response.data != null) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      return null;
    } catch (e) {
      log('Bus booking error: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> _getFallbackProfiles() {
    return [
      {
        'operator_name': 'GIGM (Sandbox)',
        'operator_code': 'GIGM',
        'origin': 'Lagos',
        'destination': 'Abuja',
        'price_ngn': 7500.0,
        'price_kobo': 750000,
        'seats_available': 12,
        'vehicle_ref': 'GIGM-BUS-0042',
        'vehicle_class': 'executive',
        'rating': 4.3,
      },
      {
        'operator_name': 'ABC Transport (Sandbox)',
        'operator_code': 'ABC',
        'origin': 'Lagos',
        'destination': 'Abuja',
        'price_ngn': 6500.0,
        'price_kobo': 650000,
        'seats_available': 7,
        'vehicle_ref': 'ABC-BUS-0017',
        'vehicle_class': 'standard',
        'rating': 4.0,
      },
    ];
  }
}
