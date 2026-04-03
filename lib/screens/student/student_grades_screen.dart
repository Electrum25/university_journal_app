import 'package:flutter/material.dart';
import '../../api/student_service.dart';

class StudentGradesScreen extends StatefulWidget {
  final String studentId;
  const StudentGradesScreen({super.key, required this.studentId});

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  late Future<Map<String, dynamic>> _reportFuture;

  @override
  void initState() {
    super.initState();
    // Загружаем данные при инициализации
    _reportFuture = StudentService.getMyReport(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя успеваемость'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          // 1. Состояние загрузки
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Обработка ошибок
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          }

          // 3. Проверка наличия данных
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Данные не найдены'));
          }

          final data = snapshot.data!;
          // Используем пустые списки, если пришел null с бэкенда
          final grades = (data['grades'] as List<dynamic>?) ?? [];
          final subjects = (data['subjects'] as List<dynamic>?) ?? [];

          if (subjects.isEmpty) {
            return const Center(child: Text('Вы пока не зачислены ни на один предмет'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              
              // Безопасное получение ID и имени предмета
              final String subjectId = subject['subjectId']?.toString() ?? '';
             final String subjectName = subject['subjectName']?.toString() ?? 'Без названия';

              // Фильтруем оценки только для этого предмета
              final subjectGrades = grades.where((g) => g['subjectId'] == subjectId).toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: const Icon(Icons.book, color: Colors.green),
                  title: Text(
                    subjectName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Получено оценок: ${subjectGrades.length}'),
                  children: [
                    if (subjectGrades.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('По этому предмету оценок пока нет'),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Работа')),
                            DataColumn(label: Text('Балл')),
                            DataColumn(label: Text('Комментарий')),
                          ],
                          rows: subjectGrades.map((g) {
                            return DataRow(cells: [
                              // Добавляем проверку на null для каждого поля внутри ячейки
                              DataCell(Text('Лаб. №${g['labNumber'] ?? '?'}')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${g['score'] ?? 0}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ),
                              ),
                              DataCell(Text(
                                (g['comment'] == null || g['comment'].toString().isEmpty) 
                                    ? '-' 
                                    : g['comment'].toString()
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}