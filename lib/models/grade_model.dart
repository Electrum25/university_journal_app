class Grade {
  final String id;
  final int value;
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
      date: DateTime.parse(json['date']),
      subjectId: json['subjectId'],
      studentId: json['studentId'],
    );
  }
}