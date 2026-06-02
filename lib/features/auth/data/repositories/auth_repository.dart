import 'dart:developer';
import '../../../../core/network/api_client.dart';

class AuthRepository {
  final _client = ApiClient.instance;

  // ── helpers ────────────────────────────────────────────────────────────────

  String _toE164(String phone) {
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0')) return '+234${phone.substring(1)}';
    return '+234$phone';
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> register({
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
      return response.data;
    } catch (e) {
      log('Register error: $e');
      return {'success': false, 'message': e.toString()};
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
      return response.data;
    } catch (e) {
      log('Login error: $e');
      return null;
    }
  }

  // ── Verify phone ───────────────────────────────────────────────────────────

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
  //
  // Strategy (in order):
  //   1. Use the JWT already in memory (set during login/register auto-login).
  //   2. If no JWT, re-login with the supplied phone+password to get one.
  //   3. Send phone in the body as a last-resort fallback for the public endpoint.

  Future<bool> setPin({
    required String pin,
    required String confirmPin,
    required String phone,
    required String password,
  }) async {
    try {
      final e164 = _toE164(phone);

      // Ensure we have a token — re-login if memory cache is empty
      if (_client.accessToken == null || _client.accessToken!.isEmpty) {
        log('SetPIN: no token in memory — re-logging in');
        final loginResult = await login(phone: phone, password: password);
        if (loginResult == null || loginResult['data'] == null) {
          log('SetPIN: re-login failed');
          return false;
        }
      }

      log('SetPIN: token present — ${_client.accessToken?.substring(0, 20)}...');

      final response = await _client.dio.post('/api/v1/auth/set-pin', data: {
        'pin': pin,
        'confirm_pin': confirmPin,
        'phone': e164,
      });
      log('SetPIN response: ${response.statusCode} ${response.data}');
      return response.statusCode == 200;
    } catch (e) {
      log('SetPIN error: $e');
      return false;
    }
  }
}
