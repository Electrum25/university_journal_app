import 'package:flutter/material.dart';

enum AttendanceStatus {
  Present,
  Absent,
  ValidReason,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.Present:
        return 'Присутствует';
      case AttendanceStatus.Absent:
        return 'Отсутствует';
      case AttendanceStatus.ValidReason:
        return 'Уважительная причина';
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatus.Present:
        return Icons.check_circle;
      case AttendanceStatus.Absent:
        return Icons.cancel;
      case AttendanceStatus.ValidReason:
        return Icons.assignment_late;
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.Present:
        return Colors.green;
      case AttendanceStatus.Absent:
        return Colors.red;
      case AttendanceStatus.ValidReason:
        return Colors.orange;
    }
  }
}

class AttendanceModel {
  final String attendanceId;
  final String studentId;
  final String subjectId;
  final DateTime date;
  final AttendanceStatus status;

  AttendanceModel({
    required this.attendanceId,
    required this.studentId,
    required this.subjectId,
    required this.date,
    required this.status,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      attendanceId: json['attendanceId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      date: DateTime.parse(json['date']?.toString() ?? DateTime.now().toIso8601String()),
      status: _parseStatus(json['status']),
    );
  }

  static AttendanceStatus _parseStatus(dynamic status) {
    if (status == null) return AttendanceStatus.Absent;

    if (status is int) {
      switch (status) {
        case 0: return AttendanceStatus.Present;
        case 1: return AttendanceStatus.Absent;
        case 2: return AttendanceStatus.ValidReason;
        default: return AttendanceStatus.Absent;
      }
    }

    if (status is String) {
      switch (status) {
        case 'Present': return AttendanceStatus.Present;
        case 'Absent': return AttendanceStatus.Absent;
        case 'ValidReason': return AttendanceStatus.ValidReason;
        default: return AttendanceStatus.Absent;
      }
    }

    return AttendanceStatus.Absent;
  }

  Map<String, dynamic> toJson() {
    return {
      'attendanceId': attendanceId,
      'studentId': studentId,
      'subjectId': subjectId,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }
}