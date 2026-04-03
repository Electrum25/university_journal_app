class Grade {
  final String id;
  final int value; // 2, 3, 4, 5
  final DateTime date;
  final String subjectId;
  final String studentId;

  Grade({
    required this.id,
    required this.value,
    required this.date,
    required this.subjectId,
    required this.studentId,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'],
      value: json['value'],
      // Превращаем строку даты из C# в объект DateTime в Dart
      date: DateTime.parse(json['date']),
      subjectId: json['subjectId'],
      studentId: json['studentId'],
    );
  }
}