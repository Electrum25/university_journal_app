import 'package:flutter/material.dart';
import '../../api/admin_service.dart';
import '../../models/subject_model.dart';

class SubjectEnrollScreen extends StatefulWidget {
  final SubjectModel subject;
  const SubjectEnrollScreen({super.key, required this.subject});

  @override
  State<SubjectEnrollScreen> createState() => _SubjectEnrollScreenState();
}

class _SubjectEnrollScreenState extends State<SubjectEnrollScreen> {
  List<dynamic> _groups = [];
  List<dynamic> _students = [];
  String? _selectedGroupId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() async {
    final groups = await AdminService.getAllGroups();
    setState(() => _groups = groups);
  }

  void _loadStudents(String groupId) async {
    setState(() => _isLoading = true);
    final students = await AdminService.getStudentsWithEnrollment(groupId, widget.subject.id);
    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  void _enrollAll() async {
    int count = 0;
    for (var student in _students) {
      if (student['isEnrolled'] == false) {
        try {
          await AdminService.enrollStudent(student['studentId'], widget.subject.id);
          count++;
        } catch (e) {
          debugPrint("Ошибка при зачислении ${student['lastName']}: $e");
        }
      }
    }
    _loadStudents(_selectedGroupId!); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Зачислено новых студентов: $count')),
    );
  }

  void _showUnlinkDialog(String studentId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отчисление'),
        content: Text('Вы уверены, что хотите отвязать студента $name от предмета?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await AdminService.unlinkStudent(studentId, widget.subject.id);
                Navigator.pop(ctx);
                _loadStudents(_selectedGroupId!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Студент отвязан от предмета')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ошибка при удалении связи')),
                );
              }
            },
            child: const Text('Да, отвязать', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Зачисление: ${widget.subject.name}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Выберите группу',
                border: OutlineInputBorder(),
              ),
              items: _groups.map((g) => DropdownMenuItem(
                value: g['groupId'].toString(),
                child: Text(g['groupName']),
              )).toList(),
              onChanged: (val) {
                if (val != null) {
                  _selectedGroupId = val;
                  _loadStudents(val);
                }
              },
            ),
          ),
          if (_isLoading) const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _students.length,
              itemBuilder: (ctx, i) {
                final s = _students[i];
                final bool isEnrolled = s['isEnrolled'] ?? false;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isEnrolled ? Colors.green.shade100 : Colors.blue.shade100,
                    child: Icon(
                      isEnrolled ? Icons.check : Icons.person_add_alt_1,
                      color: isEnrolled ? Colors.green : Colors.blue,
                    ),
                  ),
                  title: Text(
                    '${s['lastName']} ${s['firstName']}',
                    style: TextStyle(
                      color: isEnrolled ? Colors.grey : Colors.black,
                      fontWeight: isEnrolled ? FontWeight.normal : FontWeight.bold,
                      decoration: isEnrolled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(isEnrolled ? 'Уже зачислен' : 'Не зачислен'),
                  trailing: isEnrolled 
                    ? IconButton(
                        icon: const Icon(Icons.person_remove_outlined, color: Colors.orange),
                        tooltip: 'Отвязать от предмета',
                        onPressed: () => _showUnlinkDialog(s['studentId'], s['lastName']),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          try {
                            await AdminService.enrollStudent(s['studentId'], widget.subject.id);
                            _loadStudents(_selectedGroupId!);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ошибка зачисления')),
                            );
                          }
                        },
                        child: const Text('Зачислить'),
                      ),
                );
              },
            ),
          ),
          if (_students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.group_add),
                  label: const Text('Привязать всех новых'),
                  onPressed: _enrollAll,
                ),
              ),
            ),
        ],
      ),
    );
  }
}