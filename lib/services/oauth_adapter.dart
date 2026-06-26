import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OAuthAdapter {
  static const String _clientId = 'university_journal_mobile';
  static const String _clientSecret = 'secret';
  static const String _redirectUri = 'com.universityjournal:/oauth2redirect';
  static const String _issuer = 'https://localhost:7070';
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  static String _codeVerifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
  static String _codeChallenge = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';

  static Future<void> login() async {
    final authUrl = Uri.parse(
      '$_issuer/connect/authorize?'
      'response_type=code&'
      'client_id=$_clientId&'
      'redirect_uri=${Uri.encodeComponent(_redirectUri)}&'
      'scope=openid%20profile%20email%20roles%20api%20offline_access&'
      'code_challenge=$_codeChallenge&'
      'code_challenge_method=S256',
    );

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Не удалось открыть браузер');
    }
  }

  static Future<void> exchangeCodeForToken(String code) async {
    final dio = Dio(BaseOptions(
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    ));

    final response = await dio.post(
      '$_issuer/connect/token',
      data: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirectUri,
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'code_verifier': _codeVerifier,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      await _saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        expiresIn: data['expires_in'],
      );
    } else {
      throw Exception('Ошибка обмена кода: ${response.statusCode}');
    }
  }

  static Future<void> _saveTokens({
    required String accessToken,
    String? refreshToken,
    int? expiresIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}