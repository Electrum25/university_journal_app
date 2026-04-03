class SubjectModel {
  final String id;
  final String name;
  final String teacherId;
  final int totalHours; // Новое поле

  SubjectModel({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.totalHours,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      // Обрабатываем возможные варианты регистра (PascalCase от C# или camelCase от JSON)
      id: (json['subjectId'] ?? json['SubjectId'] ?? '').toString(),
      name: (json['subjectName'] ?? json['SubjectName'] ?? 'Без названия').toString(),
      teacherId: (json['teacherId'] ?? json['TeacherId'] ?? '').toString(),
      totalHours: json['totalHours'] ?? json['TotalHours'] ?? 0, // Парсим часы
    );
  }
}