import 'package:flutter/material.dart';
import '../../api/teacher_service.dart';

class SubjectJournalScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String teacherId;

  const SubjectJournalScreen({super.key, required this.subjectId, required this.subjectName, required this.teacherId});

  @override
  State<SubjectJournalScreen> createState() => _SubjectJournalScreenState();
}

class _SubjectJournalScreenState extends State<SubjectJournalScreen> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      // Загружаем студентов и оценки параллельно
      _dataFuture = _fetchJournalData();
    });
  }

  Future<Map<String, dynamic>> _fetchJournalData() async {
    final students = await TeacherService.getEnrolledStudents(widget.subjectId);
    final grades = await TeacherService.getGradesBySubject(widget.subjectId); // Добавь этот метод в сервис!
    return {'students': students, 'grades': grades};
  }

  void _openGradeInput(String studentId, int labNumber, dynamic grade) {
  final controller = TextEditingController(text: grade?['score']?.toString() ?? '');
  
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Лабораторная №$labNumber'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Введите балл'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        ElevatedButton(
          onPressed: () async {
            if (grade != null) {
              // ОБНОВЛЕНИЕ
              await TeacherService.updateGrade(
                gradeId: grade['gradeId'], 
                score: int.parse(controller.text),
                comment: '',
              );
            } else {
              // СОЗДАНИЕ
              await TeacherService.createGrade(
                  studentId: studentId,
                  subjectId: widget.subjectId,
                  labNumber: labNumber,
                  score: int.parse(controller.text),
                  comment: '',
                  teacherId: widget.teacherId);
            }
            if (!mounted) return;
            Navigator.pop(ctx);
            _loadData(); 
          },
          child: const Text('Сохранить'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final students = snapshot.data!['students'] as List<dynamic>;
          final grades = snapshot.data!['grades'] as List<dynamic>;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                border: TableBorder.all(color: Colors.grey.shade300),
                columns: [
                  const DataColumn(label: Text('Студент')),
                  ...List.generate(20, (i) => DataColumn(label: Text('Л${i + 1}'))),
                ],
                rows: students.map((s) {
                  return DataRow(cells: [
                    DataCell(Text('${s['lastName']} ${s['firstName']}')),
                    ...List.generate(20, (labIndex) {
                      int labNum = labIndex + 1;
                      // Ищем оценку для этого студента и этой лабы
                      var grade = grades.firstWhere(
                        (g) => g['studentId'] == s['studentId'] && g['labNumber'] == labNum,
                        orElse: () => null,
                      );
                      return DataCell(
  Center(child: Text(grade != null ? grade['score'].toString() : '-')),
  // Передаем сам объект grade целиком, чтобы в диалоге был доступ к gradeId
  onTap: () => _openGradeInput(s['studentId'], labNum, grade), 
);
                    }),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}