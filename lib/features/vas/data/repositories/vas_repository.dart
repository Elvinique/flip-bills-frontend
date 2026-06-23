import 'dart:developer';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class VasRepository {
  final _client = ApiClient.instance;

  // ── Catalog ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getCatalog() async {
    try {
      final response = await _client.dio.get('/api/v1/vas/catalog');
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      log('VAS catalog error: $e');
      return null;
    }
  }

  // ── Airtime ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> buyAirtime({
    required String phone,
    required int amountKobo,
    required String network,
    required String transactionPin,
  }) async {
    try {
      final response = await _client.dio.post('/api/v1/vas/airtime', data: {
        'phone': phone,
        'amount': amountKobo,
        'network': network,
        'transaction_pin': transactionPin,
      });
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      log('Airtime purchase error: $e');
      final msg = _extractErrorMessage(e, 'Airtime purchase failed. Please try again.');
      throw Exception(msg);
    }
  }

  // ── Data ─────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> buyData({
    required String phone,
    required String network,
    required String planCode,
    required String transactionPin,
  }) async {
    try {
      final response = await _client.dio.post('/api/v1/vas/data', data: {
        'phone': phone,
        'network': network,
        'plan_code': planCode,
        'transaction_pin': transactionPin,
      });
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      log('Data purchase error: $e');
      final msg = _extractErrorMessage(e, 'Data purchase failed. Please try again.');
      throw Exception(msg);
    }
  }

  // ── Electricity ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> payElectricity({
    required String meterNumber,
    required String disco,
    required int amountKobo,
    required String transactionPin,
    String meterType = 'prepaid',
  }) async {
    try {
      final response = await _client.dio.post('/api/v1/vas/electricity', data: {
        'meter_number': meterNumber,
        'disco': disco,
        'amount': amountKobo,
        'meter_type': meterType,
        'transaction_pin': transactionPin,
      });
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      log('Electricity payment error: $e');
      return null;
    }
  }

  // ── Betting ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fundBetting({
    required String customerId,
    required String provider,
    required int amountKobo,
    required String transactionPin,
  }) async {
    try {
      final response = await _client.dio.post('/api/v1/vas/betting', data: {
        'customer_id': customerId,
        'provider': provider,
        'amount': amountKobo,
        'transaction_pin': transactionPin,
      });
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      log('Betting fund error: $e');
      return null;
    }
  }

  // ── TV / Cable ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> payTvCable({
    required String smartCardNumber,
    required String provider,
    required String planCode,
  }) async {
    try {
      final response = await _client.dio.post('/api/v1/vas/tv-cable', data: {
        'smart_card_number': smartCardNumber,
        'provider': provider,
        'plan_code': planCode,
      });
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      log('TV cable payment error: $e');
      return null;
    }
  }

  // ── Transaction lookup ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getTransaction(String reference) async {
    try {
      final response =
          await _client.dio.get('/api/v1/vas/transactions/$reference');
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      log('VAS transaction lookup error: $e');
      return null;
    }
  }

  String _extractErrorMessage(dynamic e, String defaultMsg) {
    if (e is DioException) {
      if (e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
    }
    return defaultMsg;
  }
}
