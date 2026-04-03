class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String? patronymic; // Отчество (если есть)
  final String? groupName;  // Название группы (из связанной сущности Group)

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.patronymic,
    this.groupName,
  });

  // Геттер для удобного вывода полного имени
  String get fullName => '$lastName $firstName ${patronymic ?? ''}'.trim();

  // "Переводчик" из JSON (текста от сервера) в объект Dart
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      // В C# поля называются FirstName, но ASP.NET по умолчанию 
      // превращает их в firstName (camelCase) для JSON
      firstName: json['firstName'] ?? 'Не указано',
      lastName: json['lastName'] ?? '',
      patronymic: json['patronymic'],
      groupName: json['groupName'],
    );
  }

  // На случай, если нужно будет отправить данные обратно на сервер
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'patronymic': patronymic,
    };
  }
}