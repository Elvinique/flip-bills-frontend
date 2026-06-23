import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;
  late final Dio dio;

  // In-memory token cache — primary store; survives the session
  String? _accessToken;
  String? _refreshToken;

  // Public getter so repository can check without going through storage
  String? get accessToken => _accessToken;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: false,
    ),
  );

  // Use local backend for development with physical device
  // static const String baseUrl = 'http://192.168.43.167:8080';
  static const String baseUrl = 'https://flip-bills-backend-production.up.railway.app';

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 45),
        // Accept any 2xx status code — backend uses 201 for register
        validateStatus: (status) => status != null && status >= 200 && status < 300,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
          // Always use in-memory token first for speed
          final token = _accessToken ?? await _readToken('access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            // Keep in-memory cache warm
            _accessToken ??= token;
          }
          return handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefreshToken();
            if (refreshed && _accessToken != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $_accessToken';
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _readToken(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _writeToken(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      } catch (_) {}
    }
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = _refreshToken ?? await _readToken('refresh_token');
      if (refreshToken == null) return false;
      final response = await Dio().post(
        '$baseUrl/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      if (response.statusCode == 200) {
        final data = response.data['data'];
        await saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    // Also set on default headers so every request gets it immediately
    dio.options.headers['Authorization'] = 'Bearer $accessToken';
    log('ApiClient: token cached in memory');
    // Persist async — don't await so we never block on storage failures
    _writeToken('access_token', accessToken);
    _writeToken('refresh_token', refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    dio.options.headers.remove('Authorization');
    try { await _storage.deleteAll(); } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }

  Future<bool> isLoggedIn() async {
    if (_accessToken != null && _accessToken!.isNotEmpty) return true;
    final token = await _readToken('access_token');
    if (token != null && token.isNotEmpty) {
      _accessToken = token;
      dio.options.headers['Authorization'] = 'Bearer $token';
      return true;
    }
    return false;
  }
}