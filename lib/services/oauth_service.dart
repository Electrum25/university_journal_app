import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/io.dart';
import '../config.dart';          
import '../api/api_client.dart';

class OAuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  static const String _clientId = 'university_journal_mobile';
  static const String _clientSecret = 'secret';
  static const String _issuer = 'https://localhost:7070'; 
  static const String _redirectUri = 'https://localhost:7070/callback';

  static Future<void> login(String username, String password) async {
    final dio = await ApiClient.instance;
    try {
      final response = await dio.post(
        '/connect/token',
        data: {
          'grant_type': 'password',
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'username': username,
          'password': password,
          'scope': 'openid profile email roles offline_access',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка авторизации: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      await saveTokens(accessToken, refreshToken);
    } on DioException catch (e) {
      throw Exception('Ошибка соединения: ${e.message}');
    }
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    final dio = await ApiClient.instance;
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Пользователь не авторизован');
    }

    final response = await dio.get(
      '/connect/userinfo',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode != 200) {
      throw Exception('Не удалось получить данные пользователя');
    }

    final data = response.data as Map<String, dynamic>;
    final sub = data['sub'] as String? ?? '';
    String role = 'Student';
    if (data['role'] is List) {
      role = (data['role'] as List).firstOrNull ?? 'Student';
    } else if (data['role'] is String) {
      role = data['role'] as String;
    }
    return {'sub': sub, 'role': role};
  }

  static Future<Map<String, dynamic>> getProfile(String sub, String role) async {
    final dio = await ApiClient.instance;
    try {
      String endpoint;
      if (role == 'Teacher') {
        endpoint = '/api/Users/teacher-profile/by-identity/$sub';
      } else if (role == 'Student') {
        endpoint = '/api/Users/student-profile/by-identity/$sub';
      } else {
        return {'id': sub};
      }

      final response = await dio.get(endpoint);
      if (response.statusCode == 200) {
        if (role == 'Teacher') {
          return {'id': response.data['teacherId'] as String? ?? ''};
        } else {
          return {
            'id': response.data['studentId'] as String? ?? '',
            'groupId': response.data['groupId']?.toString(),
          };
        }
      }
      return {'id': ''};
    } catch (e) {
      debugPrint('Ошибка получения профиля: $e');
      return {'id': ''};
    }
  }


  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    debugPrint('Токены сохранены');
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    debugPrint('Токены удалены (выход выполнен локально)');
  }



  @Deprecated('Используйте login() для Password Flow')
  static Future<String> openLoginPage() {
    throw UnsupportedError('openLoginPage не поддерживается. Используйте login().');
  }

  @Deprecated('Используйте login() для Password Flow')
  static Future<void> exchangeCode(String code, String codeVerifier) {
    throw UnsupportedError('exchangeCode не поддерживается. Используйте login().');
  }
}