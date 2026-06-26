class Teacher {
  final String id;
  final String firstName;
  final String lastName;
  final String? patronymic;
  final String department; 
  final List<String> subjects; 

  Teacher({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.patronymic,
    required this.department,
    this.subjects = const [],
  });

  String get fullName => '$lastName $firstName ${patronymic ?? ''}'.trim();

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      patronymic: json['patronymic'],
      department: json['department'] ?? 'Общая кафедра',
      subjects: List<String>.from(json['subjects'] ?? []),
    );
  }
}