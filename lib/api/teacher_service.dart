import 'api_client.dart';
import 'package:dio/dio.dart';
import '../models/subject_model.dart';
import 'package:flutter/foundation.dart';

class TeacherService {
  static Future<List<SubjectModel>> getMySubjects(String teacherId) async {
    // Если ID пустой, просто не мучаем сервер и возвращаем пустой список
    if (teacherId.trim().isEmpty) {
      debugPrint("TeacherService: teacherId is empty, skipping request.");
      return [];
    }

    try {
      final dio = await ApiClient.instance;
      final response = await dio.get('/api/Subjects/teacher/$teacherId');
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => SubjectModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      // Печатаем ошибку, но не роняем приложение
      debugPrint("TeacherService Error: $e");
    }
    return [];
  }

  static Future<List<dynamic>> getEnrolledStudents(String subjectId) async {
    if (subjectId.isEmpty) return [];
    try {
      final dio = await ApiClient.instance;
      final response = await dio.get('/api/Subjects/enrolled-students/$subjectId');
      return response.data as List;
    } catch (e) {
      return [];
    }
  }

  static Future<void> createGrade({
    required String studentId,
    required String subjectId,
    required int labNumber,
    required int score,
    String? comment,
    required String teacherId,
  }) async {
    final dio = await ApiClient.instance;
    await dio.post(
      '/api/Grades',
      data: {
        "studentId": studentId,
        "subjectId": subjectId,
        "labNumber": labNumber,
        "score": score,
        "comment": comment ?? "",
      },
      options: Options(headers: {"teacherId": teacherId}),
    );
  }

  static Future<List<dynamic>> getGradesBySubject(String subjectId) async {
    try {
      // Правильно получаем экземпляр Dio через твой ApiClient
      final dio = await ApiClient.instance; 
      
      final response = await dio.get('/api/Grades/subject/$subjectId');
      
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Не удалось загрузить оценки');
      }
    } catch (e) {
      debugPrint("LOG: Ошибка при загрузке оценок: $e");
      return []; 
    }
  }

  static Future<void> updateGrade({
  required String gradeId, // ID самой оценки (из таблицы)
  required int score,
  required String comment,
}) async {
  final dio = await ApiClient.instance;
  await dio.put(
    '/api/Grades',
    data: {
      "gradeId": gradeId,
      "score": score,
      "comment": comment,
    },
  );
}

}