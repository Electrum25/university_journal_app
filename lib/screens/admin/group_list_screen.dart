import 'package:flutter/material.dart';
import '../../api/admin_service.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  late Future<List<Map<String, dynamic>>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _groupsFuture = AdminService.getGroups();
  }

  void _addDialog() {
  final nameController = TextEditingController();
  final specController = TextEditingController();
  final yearController = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Новая группа'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Название группы')),
            TextField(controller: specController, decoration: const InputDecoration(labelText: 'Специализация')),
            TextField(
  controller: yearController, 
  decoration: const InputDecoration(labelText: 'Год (курс)'), 
  keyboardType: TextInputType.number, 
),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        ElevatedButton(
            onPressed: () async {
    final data = {
      "groupName": nameController.text, 
      "specialization": specController.text,
      "year": int.tryParse(yearController.text) ?? 0,
    };

    await AdminService.createGroup(data);
    
    final updatedFuture = AdminService.getGroups();
    
    if (mounted) {
      Navigator.pop(context);
      setState(() {
        _groupsFuture = updatedFuture;
      });
    }
  },
          child: const Text('Создать'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление группами')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
    print("Пришедшие данные: ${snapshot.data?.first}"); 
  }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Групп пока нет'));
          }

          final groups = snapshot.data!;
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (_, i) {
  final group = groups[i];
  final id = group['groupId']?.toString(); 
  final name = group['groupName']?.toString() ?? 'Без названия';

  return ListTile(
    title: Text(name),
    trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: const Icon(Icons.edit, color: Colors.blue),
      onPressed: () => _editDialog(group), 
    ),
    IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () async {
        final String? id = group['groupId']?.toString(); 

        if (id == null || id.isEmpty) {
          print("Ошибка: ID группы отсутствует!");
          return;
        }
              
        try {
          await AdminService.deleteGroup(id);
          final updatedGroups = await AdminService.getGroups();
          
          if (mounted) {
            setState(() {
              _groupsFuture = Future.value(updatedGroups); 
            });
          }
        } catch (e) {
          print("Ошибка при удалении: $e");
        }
      },
    ),
  ],
),
  );
},
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDialog,
        child: const Icon(Icons.add),
      ),
    );
  }


  void _editDialog(Map<String, dynamic> group) {
  final nameController = TextEditingController(text: group['groupName']?.toString() ?? '');
  final specController = TextEditingController(text: group['specialization']?.toString() ?? '');
  final yearController = TextEditingController(text: group['year']?.toString() ?? '');
  final id = group['groupId']?.toString();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Редактировать группу'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Название группы')),
            TextField(controller: specController, decoration: const InputDecoration(labelText: 'Специализация')),
            TextField(
              controller: yearController,
              decoration: const InputDecoration(labelText: 'Год (курс)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        ElevatedButton(
          onPressed: () async {
            if (id == null || id.isEmpty) return;

            final data = {
              "groupName": nameController.text,
              "specialization": specController.text,
              "year": int.tryParse(yearController.text) ?? 0,
            };

            try {
              await AdminService.updateGroup(data);
              
              final updatedGroups = await AdminService.getGroups();
              
              if (mounted) {
                Navigator.pop(context); 
                setState(() {
                  _groupsFuture = Future.value(updatedGroups); 
                });
              }
            } catch (e) {
              print("Ошибка при обновлении: $e");
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    ),
  );
}
}