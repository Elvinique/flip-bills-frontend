import 'dart:developer';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class ProfileRepository {
  final _client = ApiClient.instance;

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

  // ── Fetch logged-in user profile ───────────────────────────────────────────
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _client.dio.get('/api/v1/user/profile');
      if (response.statusCode == 200) {
        final data = response.data;
        // Backend may nest under 'data'
        if (data is Map && data['data'] != null) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
        return Map<String, dynamic>.from(data as Map);
      }
      return null;
    } on DioException catch (e) {
      log('GetProfile DioException: ${e.response?.statusCode} ${e.response?.data}');
      return null;
    } catch (e) {
      log('GetProfile error: $e');
      return null;
    }
  }

  // ── Update profile ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (firstName != null) payload['first_name'] = firstName;
      if (lastName != null) payload['last_name'] = lastName;
      if (email != null) payload['email'] = email;

      final response =
          await _client.dio.patch('/api/v1/user/profile', data: payload);
      final ok = response.statusCode == 200;
      return {
        'success': ok,
        'message': ok
            ? 'Profile updated successfully.'
            : (response.data['message'] ?? 'Update failed.'),
        'data': ok ? response.data['data'] : null,
      };
    } on DioException catch (e) {
      log('UpdateProfile DioException: ${e.response?.statusCode} ${e.response?.data}');
      final msg = _extractErrorMessage(e, 'Failed to update profile.');
      return {'success': false, 'message': msg};
    } catch (e) {
      log('UpdateProfile error: $e');
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }

  // ── Change PIN ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> changePin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) async {
    try {
      final response =
          await _client.dio.post('/api/v1/auth/change-pin', data: {
        'current_pin': currentPin,
        'new_pin': newPin,
        'confirm_pin': confirmPin,
      });
      final ok = response.statusCode == 200;
      return {
        'success': ok,
        'message': ok
            ? 'PIN changed successfully.'
            : (response.data['message'] ?? 'Failed to change PIN.'),
      };
    } on DioException catch (e) {
      log('ChangePin DioException: ${e.response?.statusCode} ${e.response?.data}');
      final msg = _extractErrorMessage(e, 'Failed to change PIN. Please try again.');
      return {'success': false, 'message': msg};
    } catch (e) {
      log('ChangePin error: $e');
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }
}
