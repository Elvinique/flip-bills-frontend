import 'dart:developer';
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
  }) async {
    try {
      final response = await _client.dio.post('/api/v1/vas/airtime', data: {
        'phone': phone,
        'amount': amountKobo,
        'network': network,
      });
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      log('Airtime purchase error: $e');
      return null;
    }
  }

  // ── Data ─────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> buyData({
    required String phone,
    required String network,
    required String planCode,
  }) async {
    try {
      final response = await _client.dio.post('/api/v1/vas/data', data: {
        'phone': phone,
        'network': network,
        'plan_code': planCode,
      });
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      log('Data purchase error: $e');
      return null;
    }
  }

  // ── Electricity ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> payElectricity({
    required String meterNumber,
    required String disco,
    required int amountKobo,
    String meterType = 'prepaid',
  }) async {
    try {
      final response = await _client.dio.post('/api/v1/vas/electricity', data: {
        'meter_number': meterNumber,
        'disco': disco,
        'amount': amountKobo,
        'meter_type': meterType,
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
  }) async {
    try {
      final response = await _client.dio.post('/api/v1/vas/betting', data: {
        'customer_id': customerId,
        'provider': provider,
        'amount': amountKobo,
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
}
