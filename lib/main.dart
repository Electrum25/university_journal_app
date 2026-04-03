import 'package:flutter/material.dart';
// Добавь этот импорт для делегатов!
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'screens/login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем данные для форматирования дат
  await initializeDateFormatting('ru', null);
  runApp(const UniversityJournalApp());
}

class UniversityJournalApp extends StatelessWidget {
  const UniversityJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Journal',
      debugShowCheckedModeBanner: false,
      
      // Настройка локализации для виджетов Flutter (календари, кнопки и т.д.)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
      ],
      locale: const Locale('ru', 'RU'),

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}