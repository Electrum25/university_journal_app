import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

    final data = {
      "SubjectId": selectedSubjectId,
      "GroupId": selectedGroupId,
      "TeacherId": selectedTeacherId,
      "Date": selectedDate.toIso8601String(), 
      "PairNumber": selectedPair,
    };

    try {
      await AdminService.createScheduleItem(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Расписание успешно обновлено!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
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
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Группа', border: OutlineInputBorder()),
              value: selectedGroupId,
              items: groups.map((g) => DropdownMenuItem(
                value: g['groupId'].toString(),
                child: Text(g['groupName'] ?? 'Группа без имени')
              )).toList(),
              onChanged: (val) => setState(() => selectedGroupId = val),
              validator: (v) => v == null ? 'Выберите группу' : null,
            ),
            const SizedBox(height: 16),

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
                  final subject = subjects.firstWhere((e) => e['subjectId'].toString() == val);
                  selectedTeacherId = subject['teacherId']?.toString();
                });
              },
              validator: (v) => v == null ? 'Выберите предмет' : null,
            ),
            const SizedBox(height: 16),

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

            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата занятия',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today, color: Colors.orange),
                ),
                child: Text(
                  DateFormat('dd.MM.yyyy (EEEE)', 'ru').format(selectedDate),
                ),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              value: selectedPair,
              decoration: const InputDecoration(labelText: 'Пара', border: OutlineInputBorder()),
              items: List.generate(5, (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1} пара'),
              )),
              onChanged: (val) => setState(() => selectedPair = val!),
            ),
            const SizedBox(height: 12),
            Center(child: Text("Время: ${_getTimeRange(selectedPair)}", style: const TextStyle(color: Colors.grey))),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveSchedule,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white
              ),
              child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Сохранить занятие', style: TextStyle(fontSize: 16)),
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
      default: return "";
    }
  }
}