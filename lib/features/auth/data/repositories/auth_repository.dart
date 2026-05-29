import 'dart:developer';
import '../../../../core/network/api_client.dart';

class AuthRepository {
  final _client = ApiClient.instance;

  Future<Map<String, dynamic>?> register({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _client.dio.post('/api/v1/auth/register', data: {
        'phone': phone,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      });
      return response.data;
    } catch (e) {
      log('Register error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post('/api/v1/auth/login', data: {
        'phone': phone,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];
        await _client.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );
      }
      return response.data;
    } catch (e) {
      log('Login error: $e');
      return null;
    }
  }

  Future<bool> verifyPhone({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _client.dio.post('/api/v1/auth/verify-phone', data: {
        'phone': phone,
        'otp': otp,
      });
      return response.statusCode == 200;
    } catch (e) {
      log('Verify phone error: $e');
      return false;
    }
  }

  Future<bool> resendOTP(String phone) async {
    try {
      await _client.dio.post('/api/v1/auth/resend-otp', data: {
        'phone': phone,
        'purpose': 'phone_verify',
      });
      return true;
    } catch (e) {
      log('Resend OTP error: $e');
      return false;
    }
  }
}
