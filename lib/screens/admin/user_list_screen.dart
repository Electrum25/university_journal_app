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

  // Метод для обновления списка (теперь он определен)
  void _refreshUsers() {
    setState(() {
      _usersFuture = AdminService.getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пользователи системы')),
      body: FutureBuilder<List<UserManagementModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Пользователей пока нет'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              // Собираем ФИО
              String fullName = [user.lastName, user.firstName, user.patronymic]
                  .where((s) => s != null && s.isNotEmpty)
                  .join(' ');

              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.role.isNotEmpty ? user.role[0].toUpperCase() : '?'),
                ),
                title: Text(
                  fullName.isEmpty ? (user.login ?? 'Без логина') : fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Логин: ${user.login} • Роль: ${user.role}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editUserDialog(user), // Передаем модель
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(user), // Используем готовый метод удаления
                    ),
                  ],
                ),
              );
            },
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
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
              title: Text("Выберите тип",
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
    );

    if (role != null && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RegistrationScreen(roleType: role)),
      );

      if (result == true) {
        _refreshUsers();
      }
    }
  }

  void _confirmDelete(UserManagementModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление'),
        content: Text('Удалить пользователя ${user.login}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await AdminService.deleteUser(user.userId);
                if (mounted) {
                  Navigator.pop(ctx);
                  _refreshUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пользователь удален')),
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

  // Исправленный диалог редактирования под Модель и DTO
  void _editUserDialog(UserManagementModel user) {

  final firstNameController =
      TextEditingController(text: user.firstName ?? "");

  final lastNameController =
      TextEditingController(text: user.lastName ?? "");

  final patronymicController =
      TextEditingController(text: user.patronymic ?? "");

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Редактировать пользователя'),
      content: Column(
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

          if (user.role == "1" || user.role == "Teacher")
            TextField(
              controller: patronymicController,
              decoration: const InputDecoration(labelText: 'Отчество'),
            ),
        ],
      ),
      actions: [

        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),

        ElevatedButton(
  onPressed: () async {
    try {
      if (user.role == "1" || user.role == "Teacher") {
  await AdminService.updateTeacher(
    // Передаем ID профиля, а не аккаунта!
    teacherId: user.profileId ?? "", 
    firstName: firstNameController.text,
    lastName: lastNameController.text,
    patronymic: patronymicController.text,
  );
} else if (user.role == "2" || user.role == "Student") {
  await AdminService.updateStudent(
    // Здесь тоже ID профиля студента
    studentId: user.profileId ?? "", 
    firstName: firstNameController.text,
    lastName: lastNameController.text,
    groupId: user.groupId,
  );
}

      if (mounted) {
        Navigator.pop(context);
        _refreshUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные обновлены')),
        );
      }
    } catch (e) {
      // Расширенная диагностика ошибки 400
      if (e is DioException) {
        final serverMessage = e.response?.data;
        print("ОШИБКА СЕРВЕРА (400): $serverMessage");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $serverMessage')),
          );
        }
      } else {
        print("Ошибка: $e");
      }
    }
  },
  child: const Text('Сохранить'),
),
      ],
    ),
  );
}
}