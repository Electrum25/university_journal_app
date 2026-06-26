import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'admin/user_list_screen.dart';
import 'admin/group_list_screen.dart';
import 'admin/subject_management_screen.dart';
import 'teacher/teacher_subjects_screen.dart';
import 'student/student_grades_screen.dart';
import 'student/schedule_screen.dart';
import 'admin/admin_schedule_editor.dart';
import '../api/admin_service.dart';
import '../api/api_client.dart';
import '../screens/teacher/teacher_schedule_screen.dart';
import '../services/oauth_service.dart';
import 'admin/user_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final String role;
  final String profileId; 
  final String? groupId;

  const HomeScreen({
    super.key,
    required this.role,
    required this.profileId,
    this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Университетский журнал'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 30),
            _buildRoleSpecificBlock(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Добро пожаловать!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getRoleColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getRoleColor()),
          ),
          child: Text(
            'Роль: $role',
            style: TextStyle(
              color: _getRoleColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSpecificBlock(BuildContext context) {
    switch (role) {
      case 'Admin':
        return _buildAdminPanel(context);
      case 'Teacher':
        return _buildTeacherPanel(context); 
      case 'Student':
        return _buildStudentPanel(context); 
      default:
        return const Center(child: Text('Доступ ограничен'));
    }
  }

  Widget _buildAdminPanel(BuildContext context) {
    return Column(
      children: [
        _menuItem(
          Icons.group_add,
          'Управление пользователями',
          Colors.red,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserListScreen()),
          ),
        ),
        _menuItem(
          Icons.library_books,
          'Управление предметами',
          Colors.red,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SubjectManagementScreen()),
          ),
        ),
        _menuItem(
          Icons.group,
          'Управление группами',
          Colors.red,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GroupListScreen()),
          ),
        ),
        _menuItem(
          Icons.edit_calendar, 
          'Упр. расписанием', 
          Colors.orange, 
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminScheduleEditor()),
            );
          }
        ),
      ],
    );
  }

  Widget _buildTeacherPanel(BuildContext context) {
    return Column(
      children: [
        _menuItem(
          Icons.calendar_month,
          'Мое расписание',
          Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherScheduleScreen(teacherId: profileId),
            ),
          ),
        ),
        _menuItem(
          Icons.edit_note,
          'Журнал оценок',
          Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherSubjectsScreen(teacherProfileId: profileId),
            ),
          ),
        ),
        _menuItem(
          Icons.checklist,
          'Посещаемость',
          Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherScheduleScreen(teacherId: profileId),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentPanel(BuildContext context) { 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Меню студента',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _menuItem(
          Icons.fact_check, 
          'Моя успеваемость', 
          Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StudentGradesScreen(studentId: profileId)),
          ),
        ),
        _menuItem(
          Icons.schedule, 
          'Расписание', 
          Colors.green,
          onTap: () {
            debugPrint("--- НАЖАТИЕ НА РАСПИСАНИЕ ---");
            debugPrint("Текущий роль: $role");
            debugPrint("Значение groupId: '$groupId'");

            if (groupId != null && groupId != "null" && groupId!.isNotEmpty) {
              debugPrint("Перехожу на экран ScheduleScreen с ID: $groupId");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ScheduleScreen(groupId: groupId!)),
              );
            } else {
              debugPrint("ОШИБКА: Условие перехода не выполнено (groupId пуст или null)");
              _showError(context, "ID группы не найден в данных входа");
            }
          },
        ),
        _menuItem(
          Icons.person, 
          'Профиль студента', 
          Colors.green,
          onTap: () {
            print("ID студента: $profileId");
          }
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, Color color, {VoidCallback? onTap}) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Color _getRoleColor() {
    if (role == 'Admin') return Colors.red;
    if (role == 'Teacher') return Colors.orange;
    return Colors.green;
  }

  Future<void> _handleLogout(BuildContext context) async {
  await OAuthService.logout();
  if (context.mounted) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}