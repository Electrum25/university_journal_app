import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static String get baseUrl {
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'https://localhost:7070';
    } else if (Platform.isAndroid) {
      return 'https://10.0.2.2:7070';   
    }
    return 'https://localhost:7070';
  }

  static const String clientId = 'university_journal_mobile';
  static const String clientSecret = 'secret';

  static String get redirectUri {
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return '$baseUrl/callback';   
    } else {
      return 'com.universityjournal:/oauth2redirect';
    }
  }
}