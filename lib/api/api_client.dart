import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/oauth_service.dart';
import 'dart:io';
import 'package:dio/io.dart';

class ApiClient {
  static Dio? _dio;
  static const String _baseUrl = 'https://localhost:7070'; 
  static void reset() {
    _dio = null;
  }

  static Future<Dio> get instance async {
    if (_dio == null) {
      _dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ));
      if (!kIsWeb) {
  (_dio!.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
    client.badCertificateCallback = (cert, host, port) => true;
  };
}

      _dio!.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await OAuthService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await OAuthService.logout();
          }
          return handler.next(error);
        },
      ));

      if (kDebugMode) {
        _dio!.interceptors.add(LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
        ));
      }
    }
    return _dio!;
  }
}