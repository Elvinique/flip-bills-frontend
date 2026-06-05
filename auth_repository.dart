import 'dart:developer';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class AuthRepository {
  final _client = ApiClient.instance;

  // ── helpers ────────────────────────────────────────────────────────────────

  String _toE164(String phone) {
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0')) return '+234${phone.substring(1)}';
    return '+234$phone';
  }

  /// Extracts the human-readable message from a DioException response body.
  String _extractErrorMessage(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
        final err = data['error'];
        if (err is String && err.isNotEmpty) return err;
      }
    }
    return fallback;
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final e164 = _toE164(phone);
      final response = await _client.dio.post('/api/v1/auth/register', data: {
        'phone': e164,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      });
      // Backend returns 201 with {"success": true, "message": "..."}
      final body = response.data as Map<String, dynamic>? ?? {};
      return {'success': body['success'] == true, 'message': body['message'] ?? 'Registration successful.'};
    } on DioException catch (e) {
      log('Register DioException: ${e.response?.statusCode} ${e.response?.data}');
      final msg = _extractErrorMessage(e, 'Registration failed. Please try again.');
      return {'success': false, 'message': msg};
    } catch (e) {
      log('Register error: $e');
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> login({
    required String phone,
    required String password,
  }) async {
    try {
      final e164 = _toE164(phone);
      final response = await _client.dio.post('/api/v1/auth/login', data: {
        'phone': e164,
        'password': password,
      });
      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];
        await _client.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );
        log('Login success — token saved in memory');
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      log('Login DioException: ${e.response?.statusCode} ${e.response?.data}');
      final msg = _extractErrorMessage(e, 'Invalid phone number or password.');
      return {'success': false, 'message': msg, 'data': null};
    } catch (e) {
      log('Login error: $e');
      return {'success': false, 'message': 'An unexpected error occurred.', 'data': null};
    }
  }

  // ── Verify phone (PIN-based — kept for API compatibility) ──────────────────

  Future<bool> verifyPhone({required String phone, required String otp}) async {
    try {
      final e164 = _toE164(phone);
      final response = await _client.dio.post('/api/v1/auth/verify-phone', data: {
        'phone': e164,
        'otp': otp,
      });
      return response.statusCode == 200;
    } catch (e) {
      log('VerifyPhone error: $e');
      return false;
    }
  }

  // ── Resend OTP ─────────────────────────────────────────────────────────────

  Future<bool> resendOTP(String phone) async {
    try {
      final e164 = _toE164(phone);
      await _client.dio.post('/api/v1/auth/resend-otp', data: {
        'phone': e164,
        'purpose': 'phone_verify',
      });
      return true;
    } catch (e) {
      log('ResendOTP error: $e');
      return false;
    }
  }

  // ── Set PIN ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> setPin({
    required String pin,
    required String confirmPin,
    required String phone,
    required String password,
  }) async {
    try {
      final e164 = _toE164(phone);

      // Ensure we have a JWT — re-login if memory cache is empty
      if (_client.accessToken == null || _client.accessToken!.isEmpty) {
        log('SetPIN: no token in memory — re-logging in');
        final loginResult = await login(phone: phone, password: password);
        if (loginResult == null || loginResult['data'] == null) {
          log('SetPIN: re-login failed');
          return {'success': false, 'message': 'Session expired. Please log in again.'};
        }
      }

      log('SetPIN: token present — ${_client.accessToken?.substring(0, 20)}...');

      final response = await _client.dio.post('/api/v1/auth/set-pin', data: {
        'pin': pin,
        'confirm_pin': confirmPin,
        'phone': e164,
      });
      log('SetPIN response: ${response.statusCode} ${response.data}');
      final ok = response.statusCode == 200;
      return {
        'success': ok,
        'message': ok ? 'PIN set successfully.' : (response.data['message'] ?? 'Failed to set PIN.'),
      };
    } on DioException catch (e) {
      log('SetPIN DioException: ${e.response?.statusCode} ${e.response?.data}');
      final msg = _extractErrorMessage(e, 'Failed to set PIN. Please try again.');
      return {'success': false, 'message': msg};
    } catch (e) {
      log('SetPIN error: $e');
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }
}
