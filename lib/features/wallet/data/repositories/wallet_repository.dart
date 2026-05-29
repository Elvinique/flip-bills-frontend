import 'dart:developer';
import '../../../../core/network/api_client.dart';

class WalletRepository {
  final _client = ApiClient.instance;

  Future<Map<String, dynamic>?> getBalance() async {
    try {
      final response = await _client.dio.get('/api/v1/wallet/balance');
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      log('Get balance error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTransactions({int page = 1, int limit = 20}) async {
    try {
      final response = await _client.dio.get(
        '/api/v1/wallet/transactions',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      log('Get transactions error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> initializeFunding({
    required int amountKobo,
    required String provider,
  }) async {
    try {
      final response = await _client.dio.post(
        '/api/v1/wallet/initialize-funding',
        data: {'amount': amountKobo, 'provider': provider},
      );
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      log('Initialize funding error: $e');
      return null;
    }
  }
}
