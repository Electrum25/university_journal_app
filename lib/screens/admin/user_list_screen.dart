import 'package:flutter/material.dart';
import '../../api/admin_service.dart';
import '../../models/user_management_model.dart';
import 'registration_screen.dart';
import 'package:dio/dio.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<UserManagementModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = AdminService.getAllUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = AdminService.getAllUsers();
    });
  }

  bool _isTeacher(String role) {
    final r = role.toLowerCase();
    return r == "teacher" || r == "1";
  }

  bool _isStudent(String role) {
    final r = role.toLowerCase();
    return r == "student" || r == "2";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи системы'),
        actions: [
          IconButton(onPressed: _refreshUsers, icon: const Icon(Icons.refresh))
        ],
      ),
      body: FutureBuilder<List<UserManagementModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Ошибка: ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Пользователей пока нет'));
          }

          final users = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshUsers(),
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                String fullName = [user.lastName, user.firstName, user.patronymic]
                    .where((s) => s != null && s.trim().isNotEmpty)
                    .join(' ');

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _isTeacher(user.role) ? Colors.orange : Colors.blue,
                    child: Text(
                      user.role.isNotEmpty ? user.role[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    fullName.isEmpty ? (user.login ?? 'Без имени') : fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Логин: ${user.login}\nРоль: ${user.role}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editUserDialog(user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(user),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserOptions,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddUserOptions() async {
    final String? role = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
                title: Text("Выберите тип регистрации",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            ListTile(
                leading: const Icon(Icons.school),
                title: const Text("Студент"),
                onTap: () => Navigator.pop(ctx, 'Student')),
            ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Преподаватель"),
                onTap: () => Navigator.pop(ctx, 'Teacher')),
          ],
        ),
      ),
    );

    if (role != null && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RegistrationScreen(roleType: role)),
      );
      if (result == true) _refreshUsers();
    }
  }

  void _confirmDelete(UserManagementModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление'),
        content: Text('Удалить пользователя ${user.login} и все связанные данные?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await AdminService.deleteUser(user.userId);
                if (mounted) {
                  Navigator.pop(ctx);
                  _refreshUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пользователь успешно удален')),
                  );
                }
              } catch (e) {
                print("Ошибка удаления: $e");
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editUserDialog(UserManagementModel user) {
    final firstNameController = TextEditingController(text: user.firstName ?? "");
    final lastNameController = TextEditingController(text: user.lastName ?? "");
    final patronymicController = TextEditingController(text: user.patronymic ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактирование: ${user.login}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Фамилия'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'Имя'),
              ),
              const SizedBox(height: 10),
              if (_isTeacher(user.role))
                TextField(
                  controller: patronymicController,
                  decoration: const InputDecoration(labelText: 'Отчество'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              try {
                if (_isTeacher(user.role)) {
                  await AdminService.updateTeacher(
                    teacherId: user.profileId ?? "",
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    patronymic: patronymicController.text.trim(),
                  );
                } else if (_isStudent(user.role)) {
                  await AdminService.updateStudent(
                    studentId: user.profileId ?? "",
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    groupId: user.groupId,
                  );
                }

                if (mounted) {
                  Navigator.pop(context);
                  _refreshUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Данные успешно сохранены')),
                  );
                }
              } catch (e) {
                String errorMsg = "Ошибка при сохранении";
                if (e is DioException) {
                  errorMsg = e.response?.data?.toString() ?? e.message ?? errorMsg;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMsg)),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}