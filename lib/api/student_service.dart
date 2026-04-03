import 'api_client.dart';
import '../models/subject_model.dart';
import '../models/schedule_model.dart';
import 'package:flutter/foundation.dart';

class StudentService {
  // Получить предметы студента
  static Future<List<SubjectModel>> getMySubjects(String studentId) async {
    final dio = await ApiClient.instance;
    final response = await dio.get('/api/Subjects/student/$studentId');
    return (response.data as List).map((e) => SubjectModel.fromJson(e)).toList();
  }

  // Получить все оценки студента (используем твой готовый report)
  static Future<Map<String, dynamic>> getMyReport(String studentId) async {
    final dio = await ApiClient.instance;
    final response = await dio.get('/api/Grades/student-report/$studentId');
    return response.data;
  }

  // В файле student_service.dart
static Future<List<ScheduleModel>> getSchedule(String groupId, DateTime start, DateTime end) async {
  try {
    final dio = await ApiClient.instance;

    // Передаем даты в формате ISO 8601 (например: 2026-03-24T00:00:00)
    final response = await dio.get(
      '/api/Schedule/group/$groupId', 
      queryParameters: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
    );
    
    if (response.data is List) {
      return (response.data as List)
          .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  } catch (e) {
    debugPrint("LOG: Ошибка при загрузке расписания (по датам): $e");
    rethrow;
  }
}
}