import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Не забудь добавить intl в pubspec.yaml
import '../../api/admin_service.dart';

class AdminScheduleEditor extends StatefulWidget {
  const AdminScheduleEditor({super.key});

  @override
  State<AdminScheduleEditor> createState() => _AdminScheduleEditorState();
}

class _AdminScheduleEditorState extends State<AdminScheduleEditor> {
  final _formKey = GlobalKey<FormState>();
  
  String? selectedGroupId;
  String? selectedSubjectId;
  String? selectedTeacherId;
  
  // Новое: храним выбранную дату вместо индекса дня недели
  DateTime selectedDate = DateTime.now();
  int selectedPair = 1;

  List<dynamic> groups = [];
  List<dynamic> subjects = [];
  List<dynamic> teachers = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await AdminService.getScheduleFormData();
      setState(() {
        groups = data['groups'] ?? [];
        subjects = data['subjects'] ?? [];
        teachers = data['teachers'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (selectedGroupId == null || selectedSubjectId == null || selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите группу, предмет и учителя')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Подготовка данных для отправки на C# (Date в формате ISO 8601)
    final data = {
      "subjectId": selectedSubjectId,
      "groupId": selectedGroupId,
      "teacherId": selectedTeacherId,
      "date": selectedDate.toIso8601String(), // Отправляем полную дату
      "pairNumber": selectedPair,
    };

    try {
      await AdminService.createScheduleItem(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Расписание успешно обновлено!'), 
            backgroundColor: Colors.green
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        // Вывод ошибки с бэкенда (например, "Лимит нагрузки исчерпан")
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Метод для вызова календаря
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Можно ставить на месяц назад
      lastDate: DateTime.now().add(const Duration(days: 180)), // И на полгода вперед
      locale: const Locale('ru', 'RU'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.orange),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Редактор расписания')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Выбор группы
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Группа', border: OutlineInputBorder()),
              value: selectedGroupId,
              items: groups.map((g) => DropdownMenuItem(
                value: g['groupId'].toString(), 
                child: Text(g['groupName'] ?? 'Группа')
              )).toList(),
              onChanged: (val) => setState(() => selectedGroupId = val),
              validator: (v) => v == null ? 'Выберите группу' : null,
            ),
            const SizedBox(height: 16),

            // Выбор предмета
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Предмет', border: OutlineInputBorder()),
              value: selectedSubjectId,
              items: subjects.map((s) => DropdownMenuItem(
                value: s['subjectId'].toString(), 
                child: Text(s['subjectName'] ?? 'Предмет')
              )).toList(),
              onChanged: (val) {
                setState(() {
                  selectedSubjectId = val;
                  // Автоподстановка учителя из данных предмета
                  final subject = subjects.firstWhere((e) => e['subjectId'].toString() == val);
                  selectedTeacherId = subject['teacherId']?.toString();
                });
              },
              validator: (v) => v == null ? 'Выберите предмет' : null,
            ),
            const SizedBox(height: 16),

            // Выбор учителя
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Преподаватель', border: OutlineInputBorder()),
              value: selectedTeacherId,
              items: teachers.map((t) => DropdownMenuItem(
                value: t['teacherId'].toString(), 
                child: Text("${t['lastName']} ${t['firstName']}")
              )).toList(),
              onChanged: (val) => setState(() => selectedTeacherId = val),
              validator: (v) => v == null ? 'Выберите учителя' : null,
            ),
            const SizedBox(height: 16),

            // ВЫБОР ДАТЫ (Вместо дня недели)
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата занятия',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today, color: Colors.orange),
                ),
                child: Text(
                  DateFormat('dd MMMM yyyy (EEEE)', 'ru').format(selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Выбор номера пары
            DropdownButtonFormField<int>(
              value: selectedPair,
              decoration: const InputDecoration(labelText: 'Номер пары', border: OutlineInputBorder()),
              items: List.generate(6, (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1} пара'),
              )),
              onChanged: (val) => setState(() => selectedPair = val!),
            ),
            const SizedBox(height: 12),
            
            Center(
              child: Text(
                "Время: ${_getTimeRange(selectedPair)}", 
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)
              )
            ),

            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _isSaving ? null : _saveSchedule,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              child: _isSaving 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  ) 
                : const Text('Сохранить в расписание', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  String _getTimeRange(int pair) {
    switch (pair) {
      case 1: return "08:30 - 10:05";
      case 2: return "10:15 - 11:50";
      case 3: return "12:10 - 13:45";
      case 4: return "14:00 - 15:35";
      case 5: return "15:45 - 17:20";
      case 6: return "17:30 - 19:05";
      default: return "";
    }
  }
}