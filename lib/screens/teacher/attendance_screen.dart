import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/teacher_service.dart';
import '../../models/attendance_model.dart';
import '../../models/student_model.dart';
import '../../api/api_client.dart';
import 'package:dio/dio.dart';

class AttendanceScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String groupId;
  final String scheduleItemId;
  final String teacherId;
  final DateTime date;
  final int pairNumber;

  const AttendanceScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.groupId,
    required this.scheduleItemId,
    required this.teacherId,
    required this.date,
    required this.pairNumber,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Student> _students = [];
  Map<String, AttendanceStatus> _currentStatuses = {};
  Map<String, AttendanceStatus> _tempStatuses = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final students = await _fetchStudents();

    if (students.isNotEmpty) {
      final Map<String, AttendanceStatus> loadedStatuses = {};

      for (var student in students) {
        final status = await _fetchAttendanceForStudent(student.id);
        loadedStatuses[student.id] = status;
      }

      setState(() {
        _students = students;
        _currentStatuses = loadedStatuses;
        _tempStatuses.clear();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Student>> _fetchStudents() async {
    try {
      final dio = await ApiClient.instance;
      final response = await dio.get('/api/Groups/${widget.groupId}/students');

      if (response.data is List) {
        return (response.data as List).map((json) {
          final transformedJson = {
            'id': json['studentId'] ?? json['id'] ?? '',
            'firstName': json['firstName'] ?? '',
            'lastName': json['lastName'] ?? '',
            'patronymic': json['patronymic'],
            'groupName': json['groupName'],
          };
          return Student.fromJson(transformedJson);
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<AttendanceStatus> _fetchAttendanceForStudent(String studentId) async {
  try {
    final dio = await ApiClient.instance;
    final response = await dio.get('/api/Attendance/student/$studentId');

    if (response.data is List) {
      final attendances = (response.data as List)
          .map((json) => AttendanceModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final targetDate = DateTime.utc(
        widget.date.year,
        widget.date.month,
        widget.date.day,
      );

      print('🔍 Ищем запись для студента $studentId, предмет ${widget.subjectId}, дата $targetDate');
      print('📋 Найдено записей: ${attendances.length}');

      for (var a in attendances) {
        if (a.subjectId != widget.subjectId) continue;

        final attendanceDate = DateTime.utc(
          a.date.year,
          a.date.month,
          a.date.day,
        );

        if (attendanceDate == targetDate) {
          print('Найдена запись: статус ${a.status}');
          return a.status;
        }
      }
      print('Запись не найдена, возвращаем Absent');
    }
    return AttendanceStatus.Absent;
  } catch (e) {
    print('Ошибка при загрузке посещаемости: $e');
    return AttendanceStatus.Absent;
  }
}

  void _updateStatus(String studentId, AttendanceStatus newStatus) {
    setState(() {
      _tempStatuses[studentId] = newStatus;
    });
  }

  AttendanceStatus _getCurrentStatus(String studentId) {
    if (_tempStatuses.containsKey(studentId)) {
      return _tempStatuses[studentId]!;
    }
    return _currentStatuses[studentId] ?? AttendanceStatus.Absent;
  }

  Future<void> _saveAllAttendance() async {
  if (_tempStatuses.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Нет изменений для сохранения')),
    );
    return;
  }

  setState(() => _isSaving = true);

  try {
    final dio = await ApiClient.instance;
    final List<Map<String, dynamic>> requests = [];

    for (var entry in _tempStatuses.entries) {
      if (entry.key.isEmpty) continue;

      int statusInt;
      switch (entry.value) {
        case AttendanceStatus.Present:
          statusInt = 0;
          break;
        case AttendanceStatus.Absent:
          statusInt = 1;
          break;
        case AttendanceStatus.ValidReason:
          statusInt = 2;
          break;
      }

      requests.add({
        'studentId': entry.key,
        'subjectId': widget.subjectId,
        'date': widget.date.toUtc().toIso8601String(),
        'status': statusInt,
      });
    }

    if (requests.isNotEmpty) {
      await dio.post(
        '/api/Attendance/batch',
        data: requests,
        options: Options(headers: {'teacherId': widget.teacherId}),
      );

      setState(() {
        _tempStatuses.clear();
      });

      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Сохранено: ${requests.length} записей'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
    );
  } finally {
    setState(() => _isSaving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Посещаемость: ${widget.subjectName}'),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('EEEE, d MMMM', 'ru').format(widget.date)} • ${widget.pairNumber} пара',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveAllAttendance,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isSaving ? null : _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _students.isEmpty
                ? const Center(child: Text('Нет студентов в этой группе'))
                : ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final currentStatus = _getCurrentStatus(student.id);
                      return StudentAttendanceRow(
                        student: student,
                        currentStatus: currentStatus,
                        onStatusChanged: (newStatus) => _updateStatus(student.id, newStatus),
                      );
                    },
                  ),
      ),
    );
  }
}

class StudentAttendanceRow extends StatelessWidget {
  final Student student;
  final AttendanceStatus currentStatus;
  final Function(AttendanceStatus) onStatusChanged;

  const StudentAttendanceRow({
    super.key,
    required this.student,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(student.fullName, style: const TextStyle(fontSize: 16)),
            ),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: AttendanceStatus.values.map((status) {
                  final isSelected = currentStatus == status;
                  return GestureDetector(
                    onTap: () => onStatusChanged(status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? status.color.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? status.color : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon, color: status.color, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            status.displayName,
                            style: TextStyle(
                              color: isSelected ? status.color : Colors.grey.shade600,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}