import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../storage/local_storage.dart';

class ApiClient {
  static const String _productionUrl = 'https://academypro-api.codeways.co';
  
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
      onError: (DioException e, handler) async {
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
          final reqOptions = e.requestOptions;
          final candidates = [..._candidateLocalBaseUrls, _productionUrl];

          for (final candidate in candidates) {
            if (reqOptions.baseUrl == candidate) continue;

            try {
              final newOptions = Options(
                method: reqOptions.method,
                headers: reqOptions.headers,
                responseType: reqOptions.responseType,
                contentType: reqOptions.contentType,
              );

              final cleanPath = reqOptions.path.startsWith('/') ? reqOptions.path : '/${reqOptions.path}';
              final newUrl = '$candidate$cleanPath';

              final response = await dio.request(
                newUrl,
                data: reqOptions.data,
                queryParameters: reqOptions.queryParameters,
                options: newOptions,
              );

              _activeBaseUrl = candidate;
              return handler.resolve(response);
            } catch (_) {
              // Continue checking next candidate
            }
          }
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
