import 'package:flutter/material.dart';
import '../../api/admin_service.dart';
import '../../models/subject_model.dart';
import '../../models/user_management_model.dart';
import 'subject_enroll_screen.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  State<SubjectManagementScreen> createState() => _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  late Future<List<SubjectModel>> _subjectsFuture;
  List<UserManagementModel> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() {
      _subjectsFuture = AdminService.getAllSubjects();
    });
    
    try {
      final allUsers = await AdminService.getAllUsers();
      setState(() {
        _teachers = allUsers.where((u) => u.role == "Teacher" || u.role == "1").toList();
      });
    } catch (e) {
      debugPrint("Ошибка загрузки учителей: $e");
    }
  }

  void _showAddSubjectDialog() {
    final nameController = TextEditingController();
    final hoursController = TextEditingController();
    String? selectedTeacherId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Новый предмет'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название предмета',
                    hintText: 'Например: Математика',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Общее количество часов',
                    hintText: 'Например: 72',
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Преподаватель'),
                  value: selectedTeacherId,
                  items: _teachers.map((t) => DropdownMenuItem(
                    value: t.profileId, 
                    child: Text(t.fullName),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedTeacherId = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final hoursStr = hoursController.text.trim();
                final hours = int.tryParse(hoursStr) ?? 0;

                if (name.isNotEmpty && hours > 0 && selectedTeacherId != null) {
                  try {
                    await AdminService.createSubject(
                      name,
                      hours,
                      selectedTeacherId!,
                    );
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      _loadData();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка сервера: $e')),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заполните все поля (часы должны быть > 0)')),
                  );
                }
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление предметами')),
      body: FutureBuilder<List<SubjectModel>>(
        future: _subjectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Предметов пока нет'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final subject = snapshot.data![index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.book)),
                title: Text(subject.name),
                subtitle: Text('Часов: ${subject.totalHours ?? 0} | Нажмите для управления студентами'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectEnrollScreen(subject: subject),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Удаление'),
                        content: Text('Удалить предмет "${subject.name}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Да')),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await AdminService.deleteSubject(subject.id);
                      _loadData();
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubjectDialog,
        tooltip: 'Добавить предмет',
        child: const Icon(Icons.add),
      ),
    );
  }
}