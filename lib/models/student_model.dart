class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String? patronymic; 
  final String? groupName;  

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.patronymic,
    this.groupName,
  });

  String get fullName => '$lastName $firstName ${patronymic ?? ''}'.trim();

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? 'Не указано',
      lastName: json['lastName'] ?? '',
      patronymic: json['patronymic'],
      groupName: json['groupName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'patronymic': patronymic,
    };
  }
}