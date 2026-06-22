import 'dart:developer';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class TransferRepository {
  final _client = ApiClient.instance;

  /// Resolves an account name from account number + bank code via the backend.
  Future<Map<String, dynamic>?> resolveAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    try {
      final response = await _client.dio.post(
        '/api/v1/transfer/verify-account',
        data: {'account_number': accountNumber, 'bank_code': bankCode},
      );
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } on DioException catch (e) {
      log('resolveAccount error: ${e.response?.data}');
      return null;
    }
  }

  /// Returns list of supported banks from the backend (cached from Paystack).
  Future<List<Map<String, dynamic>>> getBanks() async {
    try {
      final response = await _client.dio.get('/api/v1/transfer/banks');
      if (response.statusCode == 200) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } on DioException catch (e) {
      log('getBanks error: ${e.response?.data}');
      return _fallbackBanks;
    }
  }

  /// Initiates a bank transfer.
  Future<Map<String, dynamic>?> bankTransfer({
    required String accountNumber,
    required String bankCode,
    required String accountName,
    required int amountKobo,
    required String narration,
  }) async {
    try {
      final response = await _client.dio.post(
        '/api/v1/transfer/bank',
        data: {
          'account_number': accountNumber,
          'bank_code': bankCode,
          'account_name': accountName,
          'amount': amountKobo,
          'narration': narration,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return {'error': response.data['message'] ?? 'Transfer failed'};
    } on DioException catch (e) {
      log('bankTransfer error: ${e.response?.data}');
      final msg = e.response?.data?['message'] as String? ?? 'Transfer failed';
      return {'error': msg};
    }
  }

  /// Initiates a wallet-to-wallet transfer.
  Future<Map<String, dynamic>?> walletTransfer({
    required String recipientPhone,
    required int amountKobo,
    required String narration,
  }) async {
    try {
      final response = await _client.dio.post(
        '/api/v1/transfer/wallet',
        data: {
          'recipient_phone': recipientPhone,
          'amount': amountKobo,
          'narration': narration,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return {'error': response.data['message'] ?? 'Transfer failed'};
    } on DioException catch (e) {
      log('walletTransfer error: ${e.response?.data}');
      final msg = e.response?.data?['message'] as String? ?? 'Transfer failed';
      return {'error': msg};
    }
  }

  // ── Fallback bank list shown when API is unavailable ─────────────────────
  static const _fallbackBanks = <Map<String, dynamic>>[
    {'code': '044', 'name': 'Access Bank'},
    {'code': '023', 'name': 'Citibank'},
    {'code': '063', 'name': 'Diamond Bank'},
    {'code': '050', 'name': 'Ecobank'},
    {'code': '084', 'name': 'Enterprise Bank'},
    {'code': '011', 'name': 'First Bank'},
    {'code': '214', 'name': 'First City Monument Bank'},
    {'code': '070', 'name': 'Fidelity Bank'},
    {'code': '058', 'name': 'Guaranty Trust Bank'},
    {'code': '030', 'name': 'Heritage Bank'},
    {'code': '301', 'name': 'Jaiz Bank'},
    {'code': '082', 'name': 'Keystone Bank'},
    {'code': '526', 'name': 'Moniepoint'},
    {'code': '014', 'name': 'MainStreet Bank'},
    {'code': '076', 'name': 'Polaris Bank'},
    {'code': '101', 'name': 'ProvidusBank'},
    {'code': '221', 'name': 'Stanbic IBTC Bank'},
    {'code': '068', 'name': 'Standard Chartered Bank'},
    {'code': '232', 'name': 'Sterling Bank'},
    {'code': '100', 'name': 'Suntrust Bank'},
    {'code': '032', 'name': 'Union Bank'},
    {'code': '033', 'name': 'United Bank For Africa'},
    {'code': '215', 'name': 'Unity Bank'},
    {'code': '035', 'name': 'Wema Bank'},
    {'code': '057', 'name': 'Zenith Bank'},
    {'code': '999992', 'name': 'OPay'},
    {'code': '999991', 'name': 'PalmPay'},
    {'code': '999998', 'name': 'Kuda'},
  ];
}
