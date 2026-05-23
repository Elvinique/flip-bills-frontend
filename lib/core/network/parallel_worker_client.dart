import 'package:dio/dio.dart';

class ParallelWorkerClient {
  late final Dio _dioClient;

  ParallelWorkerClient() {
    _dioClient = Dio(
      BaseOptions(
        // Set connection and response timeouts matching your PRD transaction guard windows
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Platform-Channel': 'ByeByeBill-Mobile-Enclave',
        },
      ),
    );

    // Inject logging and lifecycle interceptors to trace payload transmission drops
    _dioClient.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          // Log tracking header tokens for security auditing
          options.headers['X-Request-Timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          return handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) {
          return handler.next(error);
        },
      ),
    );
  }

  Dio get instance => _dioClient;
}