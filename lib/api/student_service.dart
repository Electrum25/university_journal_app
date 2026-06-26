import 'api_client.dart';
import '../models/subject_model.dart';
import '../models/schedule_model.dart';
import 'package:flutter/foundation.dart';

class StudentService {
  static Future<List<SubjectModel>> getMySubjects(String studentId) async {
    final dio = await ApiClient.instance;
    final response = await dio.get('/api/Subjects/student/$studentId');
    return (response.data as List).map((e) => SubjectModel.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> getMyReport(String studentId) async {
    final dio = await ApiClient.instance;
    final response = await dio.get('/api/Grades/student-report/$studentId');
    return response.data;
  }

static Future<List<ScheduleModel>> getSchedule(String groupId, DateTime start, DateTime end) async {
  try {
    final dio = await ApiClient.instance;

    final startUtc = DateTime.utc(start.year, start.month, start.day);
    final endUtc = DateTime.utc(end.year, end.month, end.day, 23, 59, 59);

    final response = await dio.get(
      '/api/Schedule/group/$groupId', 
      queryParameters: {
        'start': startUtc.toIso8601String(),
        'end': endUtc.toIso8601String(),
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