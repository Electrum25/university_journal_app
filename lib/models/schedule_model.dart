import 'package:intl/intl.dart';

class ScheduleModel {
  final String scheduleItemId;
  final String subjectName;
  final DateTime date; // Теперь используем реальную дату
  final int pairNumber;
  final String timeRange;
  final String teacherFullName;

  ScheduleModel({
    required this.scheduleItemId,
    required this.subjectName,
    required this.date,
    required this.pairNumber,
    required this.timeRange,
    required this.teacherFullName,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    // Парсим дату из строки (ISO 8601), которую присылает C#
    DateTime parsedDate = DateTime.now();
    var rawDate = json['date'] ?? json['Date'];
    if (rawDate != null) {
      parsedDate = DateTime.parse(rawDate.toString());
    }

    return ScheduleModel(
      scheduleItemId: (json['scheduleItemId'] ?? json['ScheduleItemId'] ?? '').toString(),
      subjectName: (json['subjectName'] ?? json['SubjectName'] ?? 'Без названия').toString(),
      date: parsedDate,
      pairNumber: int.tryParse((json['pairNumber'] ?? json['PairNumber'] ?? '0').toString()) ?? 0,
      timeRange: (json['timeRange'] ?? json['TimeRange'] ?? '').toString(),
      teacherFullName: (json['teacherFullName'] ?? json['TeacherFullName'] ?? 'Не назначен').toString(),
    );
  }

  // Удобный геттер для получения названия дня недели на русском
  String get russianDayName {
    // Использует пакет intl для локализации
    return DateFormat('EEEE', 'ru').format(date);
  }
}