import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../storage/local_storage.dart';

class ApiClient {
  static const String _productionUrl = 'https://academypro-api.tata-elash34.workers.dev';
  
  static List<String> get _candidateLocalBaseUrls {
    final host = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost';
    return [
      'http://$host:8787',
      'http://$host:3000',
      'http://$host:8080',
      'http://$host:80',
    ];
  }

  static String _activeBaseUrl = _productionUrl;
  static String get baseUrl => _activeBaseUrl;

  late final Dio dio;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = LocalStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.error is SocketException) {
          // Trigger network state recheck on connection failures
        }
        return handler.next(e);
      },
    ));
  }

  // Direct HTTP GET request
  Future<Response> getAndCache(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  // Helper method for POST requests
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await dio.post(path, data: data, queryParameters: queryParameters);
  }

  // Helper method for DELETE requests
  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await dio.delete(path, data: data, queryParameters: queryParameters);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
