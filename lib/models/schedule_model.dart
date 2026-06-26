import 'package:intl/intl.dart';

class ScheduleModel {
  final String scheduleItemId;
  final String subjectId;
  final String subjectName;
  final DateTime date;
  final int pairNumber;
  final String timeRange;
  final String teacherFullName;
  final String groupId;

  ScheduleModel({
    required this.scheduleItemId,
    required this.subjectId,
    required this.subjectName,
    required this.date,
    required this.pairNumber,
    required this.timeRange,
    required this.teacherFullName,
    required this.groupId,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    print('Парсим JSON: $json');
    
    DateTime parsedDate = DateTime.now();
    var rawDate = json['date'] ?? json['Date'];
    if (rawDate != null) {
      parsedDate = DateTime.parse(rawDate.toString());
      if (parsedDate.isUtc) {
        parsedDate = parsedDate.toLocal();
      }
    }

    return ScheduleModel(
      scheduleItemId: (json['scheduleItemId'] ?? json['ScheduleItemId'] ?? '').toString(),
      subjectId: (json['subjectId'] ?? json['SubjectId'] ?? '').toString(),
      subjectName: (json['subjectName'] ?? json['SubjectName'] ?? 'Без названия').toString(),
      date: parsedDate,
      pairNumber: (json['pairNumber'] ?? json['PairNumber'] ?? 0) as int,
      timeRange: (json['timeRange'] ?? json['TimeRange'] ?? '').toString(),
      teacherFullName: (json['teacherFullName'] ?? json['TeacherFullName'] ?? 'Не назначен').toString(),
      groupId: (json['groupId'] ?? json['GroupId'] ?? '').toString(),
    );
  }

  String get russianDayName {
    return DateFormat('EEEE', 'ru').format(date);
  }
  
  @override
  String toString() {
    return 'ScheduleModel(subjectName: $subjectName, pairNumber: $pairNumber, date: $date)';
  }
}