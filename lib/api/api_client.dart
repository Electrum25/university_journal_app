import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ApiClient {
  static Dio? _dio;

  static Future<Dio> get instance async {
    if (_dio == null) {
      _dio = Dio(BaseOptions(
        // Замени на свой порт из launchSettings.json бэкенда
        baseUrl: 'https://localhost:7070', 
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      // Настраиваем постоянное хранилище для кук
      final appDocDir = await getApplicationDocumentsDirectory();
      final cookieJar = PersistCookieJar(
        storage: FileStorage("${appDocDir.path}/.cookies/"),
      );
      
      _dio!.interceptors.add(CookieManager(cookieJar));
    }
    return _dio!;
  }
}