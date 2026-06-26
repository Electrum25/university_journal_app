import 'package:flutter/material.dart';
import '../../api/admin_service.dart';

class RegistrationScreen extends StatefulWidget {
  final String roleType;

  const RegistrationScreen({super.key, required this.roleType});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  
  String? _selectedGroupId;
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    if (widget.roleType == 'Student') {
      _loadGroups();
    }
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await AdminService.getGroups();
      setState(() {
        _groups = groups;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки групп: $e')));
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      "login": _loginController.text,
      "password": _passwordController.text,
      "firstName": _firstNameController.text,
      "lastName": _lastNameController.text,
      "patronymic": _patronymicController.text,
      if (widget.roleType == 'Student') "groupId": _selectedGroupId,
    };

    try {
      if (widget.roleType == 'Student') {
        await AdminService.registerStudent(data);
      } else {
        await AdminService.registerTeacher(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Регистрация: ${widget.roleType}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _loginController, decoration: const InputDecoration(labelText: 'Логин'), validator: (v) => v!.isEmpty ? 'Введите логин' : null),
            TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Пароль'), obscureText: true),
            TextFormField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Фамилия')),
            TextFormField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'Имя')),
            TextFormField(controller: _patronymicController, decoration: const InputDecoration(labelText: 'Отчество')),
            
            if (widget.roleType == 'Student') ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Выберите группу', border: OutlineInputBorder()),
                items: _groups.map((group) => DropdownMenuItem<String>(
                  value: group['groupId'].toString(), 
                  child: Text(group['groupName']),
                )).toList(),
                onChanged: (val) => setState(() => _selectedGroupId = val),
                validator: (v) => v == null ? 'Выберите группу' : null,
              ),
            ],
            
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _register, child: const Text('Зарегистрировать')),
          ],
        ),
      ),
    );
  }
}