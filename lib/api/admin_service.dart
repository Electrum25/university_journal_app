import '../api/api_client.dart';
import '../models/user_management_model.dart';
import '../models/subject_model.dart';
import 'package:dio/dio.dart';

class AdminService {
  static Future<List<UserManagementModel>> getAllUsers() async {
  final dio = await ApiClient.instance;
  final response = await dio.get('/api/Users');

  List<dynamic> data = response.data;
  List<UserManagementModel> users =
      data.map((json) => UserManagementModel.fromJson(json)).toList();

  for (var user in users) {
    try {
      if (user.role == "1" || user.role == "Teacher") {
  final profile = await dio.get('/api/Users/teacher-profile/${user.userId}');
  
  user.profileId = profile.data["teacherId"] ?? profile.data["id"]; 
  
  user.firstName = profile.data["firstName"];
  user.lastName = profile.data["lastName"];
  user.patronymic = profile.data["patronymic"];
}

if (user.role == "2" || user.role == "Student") {
  final profile = await dio.get('/api/Users/student-profile/${user.userId}');
  
  user.profileId = profile.data["studentId"] ?? profile.data["id"];
  
  user.firstName = profile.data["firstName"];
  user.lastName = profile.data["lastName"];
  user.groupId = profile.data["groupId"]?.toString();
}
    } catch (e) {
      print("Ошибка загрузки профиля: $e");
    }
  }

  return users;
}

  static Future<void> deleteUser(String id) async {
    final dio = await ApiClient.instance;
    await dio.delete('/api/Users/$id');
  }

  static Future<void> registerStudent(Map<String, dynamic> data) async {
    final dio = await ApiClient.instance;
    await dio.post('/api/Users/register-student', data: data);
  }

  static Future<void> registerTeacher(Map<String, dynamic> data) async {
    final dio = await ApiClient.instance;
    await dio.post('/api/Users/register-teacher', data: data);
  }

  static Future<List<Map<String, dynamic>>> getGroups() async {
  final dio = await ApiClient.instance;
  final response = await dio.get('/api/Groups'); 
  List<dynamic> data = response.data;
  return data.map((g) => Map<String, dynamic>.from(g)).toList();
}


static Future<void> deleteGroup(String id) async {
  final dio = await ApiClient.instance;
  final path = '/api/Groups/$id'; 
  print("Финальный URL запроса: $path");
  
  await dio.delete(path);
}

static Future<void> createGroup(Map<String, dynamic> data) async {
  final dio = await ApiClient.instance;
  await dio.post('/api/Groups', data: data); 
}

static Future<void> updateGroup(Map<String, dynamic> data) async {
  final dio = await ApiClient.instance;
  await dio.put('/api/Groups', data: data); 
}

static Future<void> updateUser(Map<String, dynamic> data, int role) async {
  final dio = await ApiClient.instance;

  if (role == 2) {
    await dio.put('/api/Users/student', data: data);
  } else if (role == 1) {
    await dio.put('/api/Users/teacher', data: data);
  } else {
    throw Exception("Admin нельзя обновлять этим методом");
  }
}

static Future<Map<String, dynamic>> getTeacherProfile(String userId) async {
  final dio = await ApiClient.instance;
  final response = await dio.get('/api/Users/teacher-profile/$userId');
  return Map<String, dynamic>.from(response.data);
}

static Future<Map<String, dynamic>> getStudentProfile(String userId) async {
  final dio = await ApiClient.instance;
  final response = await dio.get('/api/Users/student-profile/$userId');
  return Map<String, dynamic>.from(response.data);
}

static Future<void> updateTeacher({
  required String teacherId,
  required String firstName,
  required String lastName,
  String? patronymic,
}) async {
  final dio = await ApiClient.instance;

  final Map<String, dynamic> data = {
    "teacherId": teacherId, 
    "firstName": firstName,
    "lastName": lastName,
    "patronymic": (patronymic != null && patronymic.isNotEmpty) ? patronymic : null,
  };

  await dio.put('/api/Users/teacher', data: data);
}

static Future<void> updateStudent({
  required String studentId,
  required String firstName,
  required String lastName,
  String? groupId,
}) async {
  final dio = await ApiClient.instance;

  final Map<String, dynamic> data = {
    "studentId": studentId,
    "firstName": firstName,
    "lastName": lastName,
    "groupId": (groupId != null && groupId.isNotEmpty) ? groupId : null,
  };

  await dio.put('/api/Users/student', data: data);
}

  static Future<List<SubjectModel>> getAllSubjects() async {
  try {
    final dio = await ApiClient.instance;
    final response = await dio.get('/api/Subjects');
    
    print("ДАННЫЕ С СЕРВЕРА: ${response.data}"); 

    if (response.data is List) {
      return (response.data as List)
          .map((e) => SubjectModel.fromJson(e))
          .toList();
    }
    return [];
  } catch (e) {
    print("Ошибка загрузки предметов: $e");
    return [];
  }
}

  static Future<void> createSubject(String name, int totalHours, String teacherId) async {
  final dio = await ApiClient.instance;

  final Map<String, dynamic> data = {
    "SubjectName": name.trim(),
    "TeacherId": teacherId,
    "TotalHours": totalHours,
  };

  try {
    await dio.post('/api/Subjects', data: data);
  } on DioException catch (e) {
    print("Ошибка сервера (400/500): ${e.response?.data}");
    rethrow;
  }
}

  static Future<void> deleteSubject(String id) async {
    final dio = await ApiClient.instance;
    await dio.delete('/api/Subjects/$id');
  }


static Future<List<dynamic>> getStudentsByGroup(String groupId) async {
  final dio = await ApiClient.instance;
  final response = await dio.get('/api/Groups/$groupId/students');
  return response.data as List;
}

static Future<void> enrollStudent(String studentId, String subjectId) async {
  final dio = await ApiClient.instance;
  await dio.post('/api/Subjects/enroll', data: {
    "studentId": studentId,
    "subjectId": subjectId,
  });
}

static Future<List<dynamic>> getAllGroups() async {
  final dio = await ApiClient.instance;
  final response = await dio.get('/api/Groups');
  return response.data as List;
}

static Future<List<dynamic>> getStudentsWithEnrollment(String groupId, String subjectId) async {
  final dio = await ApiClient.instance;
  final response = await dio.get('/api/Groups/$groupId/students-with-enrollment/$subjectId');
  return response.data as List;
}

static Future<void> unlinkStudent(String studentId, String subjectId) async {
  final dio = await ApiClient.instance;
  await dio.delete('/api/Subjects/unlink', data: {
    "studentId": studentId,
    "subjectId": subjectId,
  });
}


static Future<Map<String, List<dynamic>>> getScheduleFormData() async {
    try {
      final dio = await ApiClient.instance;
      final response = await dio.get('/api/Schedule/form-data');
      
      if (response.statusCode == 200) {
        return {
          'groups': response.data['groups'] as List<dynamic>,
          'subjects': response.data['subjects'] as List<dynamic>,
          'teachers': response.data['teachers'] as List<dynamic>,
        };
      }
      throw Exception('Ошибка загрузки данных формы');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> createScheduleItem(Map<String, dynamic> data) async {
    try {
      final dio = await ApiClient.instance;
      await dio.post('/api/Schedule', data: data);
    } on DioException catch (e) {
      final message = e.response?.data ?? 'Ошибка сервера';
      throw Exception(message);
    }
  }
}