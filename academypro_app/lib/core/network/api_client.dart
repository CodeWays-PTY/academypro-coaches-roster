import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../storage/local_storage.dart';

class ApiClient {
  static const String _cloudflareUrl = 'https://academypro-api.tata-elash34.workers.dev';
  static const String _localDevUrl = 'http://localhost:3000';
  
  static String get baseUrl => _cloudflareUrl;

  late final Dio dio;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
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
        // Intercept network connection issues for GET request caching fallbacks
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.unknown) {
          final request = e.requestOptions;
          if (request.method == 'GET') {
            final cacheKey = request.path + (request.queryParameters.toString());
            final cachedData = LocalStorage.getCachedData(cacheKey);
            if (cachedData != null) {
              // Return mocked success response with cached data
              return handler.resolve(Response(
                requestOptions: request,
                data: {
                  'success': true,
                  'data': cachedData,
                  'message': 'Loaded from offline cache'
                },
                statusCode: 200,
              ));
            }
          }
        }
        return handler.next(e);
      },
    ));
  }

  // Helper method to update local cache on successful GET requests
  Future<Response> getAndCache(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await dio.get(path, queryParameters: queryParameters);
    if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
      final cacheKey = path + (queryParameters?.toString() ?? '{}');
      await LocalStorage.cacheData(cacheKey, response.data['data']);
    }
    return response;
  }

  // Helper method for POST requests
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await dio.post(path, data: data, queryParameters: queryParameters);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
