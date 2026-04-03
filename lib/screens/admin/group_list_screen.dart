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
  decoration: const InputDecoration(labelText: 'Год (курс)'), // keyboardType убран отсюда
  keyboardType: TextInputType.number, // Перенесен сюда, на уровень самого TextField
),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        ElevatedButton(
            onPressed: () async {
    // 1. Формируем данные (убедитесь, что имена ключей совпадают с C#!)
    final data = {
      "groupName": nameController.text, // или "Name" — проверьте в C#
      "specialization": specController.text,
      "year": int.tryParse(yearController.text) ?? 0,
    };

    // 2. Делаем запрос вне setState
    await AdminService.createGroup(data);
    
    // 3. Получаем новое Future
    final updatedFuture = AdminService.getGroups();
    
    if (mounted) {
      Navigator.pop(context);
      // 4. Обновляем состояние синхронно
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
    // ВЫВЕДИТЕ ЭТО В КОНСОЛЬ!
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
  // ВАЖНО: убедитесь, что ключ совпадает с тем, что вы видите в консоли
  // (Вы писали, что пришло: groupId: 40003156...)
  final id = group['groupId']?.toString(); 
  final name = group['groupName']?.toString() ?? 'Без названия';

  return ListTile(
    title: Text(name),
    trailing: Row(
  mainAxisSize: MainAxisSize.min, // Чтобы Row не занимал всю ширину строки
  children: [
    // Кнопка редактирования
    IconButton(
      icon: const Icon(Icons.edit, color: Colors.blue),
      onPressed: () => _editDialog(group), // Передаем данные конкретной группы в диалог
    ),
    // Ваша существующая кнопка удаления
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
  // Предзаполняем контроллеры текущими данными из переданной группы
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

            // Формируем обновленные данные. 
            // ВАЖНО: убедитесь, что ключ ID совпадает с тем, что ждет ваш C# (обычно это "id" или "groupId")
            final data = {
              "groupId": id, // Или "groupId": id, в зависимости от вашей C# модели UpdateGroupRequest
              "groupName": nameController.text,
              "specialization": specController.text,
              "year": int.tryParse(yearController.text) ?? 0,
            };

            try {
              // Ждем выполнения PUT запроса
              await AdminService.updateGroup(data);
              
              // Получаем свежий список
              final updatedGroups = await AdminService.getGroups();
              
              if (mounted) {
                Navigator.pop(context); // Закрываем диалог
                setState(() {
                  _groupsFuture = Future.value(updatedGroups); // Синхронно обновляем экран
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