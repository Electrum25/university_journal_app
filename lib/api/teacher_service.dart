import 'api_client.dart';
import 'package:dio/dio.dart';
import '../models/subject_model.dart';
import 'package:flutter/foundation.dart';
import '../models/schedule_model.dart';
import '../models/attendance_model.dart';

class TeacherService {
  static Future<List<SubjectModel>> getMySubjects(String teacherId) async {
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
    required String gradeId, 
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

  static Future<List<ScheduleModel>> getTeacherSchedule(
    String teacherId, 
    DateTime start, 
    DateTime end
  ) async {
    try {
      final dio = await ApiClient.instance;
      
      final startUtc = DateTime.utc(start.year, start.month, start.day);
      final endUtc = DateTime.utc(end.year, end.month, end.day, 23, 59, 59);
      
      final response = await dio.get(
        '/api/Schedule/teacher/$teacherId',
        queryParameters: {
          'start': startUtc.toIso8601String(),
          'end': endUtc.toIso8601String(),
        },
      );
      
      print('Ответ от сервера: ${response.data}');
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => ScheduleModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Ошибка загрузки расписания учителя: $e');
      return [];
    }
  }

  static Future<List<AttendanceModel>> getAttendanceBySubject(String subjectId) async {
    try {
      final dio = await ApiClient.instance;
      final response = await dio.get('/api/Attendance/subject/$subjectId');
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => AttendanceModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Ошибка загрузки посещаемости: $e');
      return [];
    }
  }

  static Future<List<AttendanceModel>> getAttendanceByStudent(String studentId) async {
    try {
      final dio = await ApiClient.instance;
      final response = await dio.get('/api/Attendance/student/$studentId');
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => AttendanceModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Ошибка загрузки посещаемости студента: $e');
      return [];
    }
  }

  static Future<void> markAttendance({
    required String studentId,
    required String subjectId,
    required DateTime date,
    required AttendanceStatus status,
    required String teacherId,
  }) async {
    try {
      final dio = await ApiClient.instance;
      
      final requestData = {
        'studentId': studentId,
        'subjectId': subjectId,
        'date': date.toUtc().toIso8601String(),
        'status': _attendanceStatusToInt(status),
      };
      
      print('Отправляем в markAttendance: $requestData');
      
      await dio.post(
        '/api/Attendance',
        data: requestData,
        options: Options(headers: {'teacherId': teacherId}),
      );
    } catch (e) {
      debugPrint('Ошибка сохранения посещаемости: $e');
      rethrow;
    }
  }

  static Future<void> markMultipleAttendance({
    required List<Map<String, dynamic>> attendances,
    required String teacherId,
  }) async {
    try {
      final dio = await ApiClient.instance;
      
      final List<Map<String, dynamic>> formattedRequests = [];
      
      for (var attendance in attendances) {
        formattedRequests.add({
          'studentId': attendance['studentId'] ?? attendance['StudentId'] ?? '',
          'subjectId': attendance['subjectId'] ?? attendance['SubjectId'] ?? '',
          'date': attendance['date'] != null 
              ? DateTime.parse(attendance['date'].toString()).toUtc().toIso8601String()
              : DateTime.now().toUtc().toIso8601String(),
          'status': _getStatusValue(attendance['status']),
        });
      }
      
      print('Отправляем batch запрос: $formattedRequests');
      
      final response = await dio.post(
        '/api/Attendance/batch',
        data: formattedRequests,
        options: Options(headers: {'teacherId': teacherId}),
      );
      
      print('Batch ответ: ${response.data}');
    } catch (e) {
      if (e is DioException) {
        print('Ошибка: ${e.response?.data}');
        print('Статус: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  static int _attendanceStatusToInt(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.Present:
        return 0;
      case AttendanceStatus.Absent:
        return 1;
      case AttendanceStatus.ValidReason:
        return 2;
      default:
        return 1;
    }
  }

  static int _getStatusValue(dynamic status) {
    if (status is int) return status;
    if (status is String) {
      switch (status) {
        case 'Present': return 0;
        case 'Absent': return 1;
        case 'ValidReason': return 2;
        default: return 1;
      }
    }
    if (status is AttendanceStatus) {
      switch (status) {
        case AttendanceStatus.Present: return 0;
        case AttendanceStatus.Absent: return 1;
        case AttendanceStatus.ValidReason: return 2;
      }
    }
    return 1;
  }
}