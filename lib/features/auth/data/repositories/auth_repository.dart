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
    String dateOfBirth = '',
  }) async {
    try {
      // phone is already in E.164 format — normalise only if needed
      final e164 = phone.startsWith('+') ? phone : _toE164(phone);
      final payload = <String, dynamic>{
        'phone': e164,
        'password': password,
        'password_confirmation': password,
        'first_name': firstName,
        'last_name': lastName,
      };
      if (dateOfBirth.isNotEmpty) payload['date_of_birth'] = dateOfBirth;

      log('Register payload: $payload');

      final response = await _client.dio.post(
        '/api/v1/auth/register',
        data: payload,
        options: Options(contentType: 'application/json'),
      );
      // Backend returns 201 with {"success": true, "message": "..."}
      final body = response.data as Map<String, dynamic>? ?? {};
      log('Register response: $body');
      return {
        'success': body['success'] == true,
        'message': body['message'] ?? 'Registration successful.',
      };
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
      final response = await _client.dio.post(
        '/api/v1/auth/login',
        data: {
          'phone': e164,
          'password': password,
        },
        options: Options(contentType: 'application/json'),
      );
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
}