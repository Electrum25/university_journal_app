import 'package:flutter/material.dart';
import '../../api/teacher_service.dart';
import '../../models/subject_model.dart';
import 'subject_journal_screen.dart';

class TeacherSubjectsScreen extends StatelessWidget {
  final String teacherProfileId;

  const TeacherSubjectsScreen({super.key, required this.teacherProfileId});

  @override
  Widget build(BuildContext context) {
    debugPrint("LOG: Открыт экран предметов для TeacherId: $teacherProfileId");

    return Scaffold(
      appBar: AppBar(title: const Text('Мои предметы')),
      body: FutureBuilder<List<SubjectModel>>( 
        future: TeacherService.getMySubjects(teacherProfileId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint("LOG: Ошибка FutureBuilder: ${snapshot.error}");
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('У вас нет назначенных предметов'));
          }

          final subjects = snapshot.data!;
          debugPrint("LOG: Получено предметов: ${subjects.length}");

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return ListTile(
                leading: const Icon(Icons.book, color: Colors.orange),
                title: Text(subject.name), 
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectJournalScreen(
                        subjectId: subject.id,
                        subjectName: subject.name,
                        teacherId: teacherProfileId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}