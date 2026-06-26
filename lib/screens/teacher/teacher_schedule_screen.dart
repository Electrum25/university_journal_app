import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/teacher_service.dart';
import '../../models/schedule_model.dart';
import 'attendance_screen.dart';

class TeacherScheduleScreen extends StatefulWidget {
  final String teacherId;

  const TeacherScheduleScreen({super.key, required this.teacherId});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  DateTime _startOfWeek = _findFirstDayOfWeek(DateTime.now());
  late Future<List<ScheduleModel>> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  static DateTime _findFirstDayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _loadSchedule() {
    final endOfWeek = _startOfWeek.add(const Duration(days: 6));
    setState(() {
      _scheduleFuture = TeacherService.getTeacherSchedule(
        widget.teacherId,
        _startOfWeek,
        endOfWeek,
      );
    });
  }

  void _changeWeek(int weeks) {
    setState(() {
      _startOfWeek = _startOfWeek.add(Duration(days: 7 * weeks));
      _loadSchedule();
    });
  }

  void _resetToCurrentWeek() {
    setState(() {
      _startOfWeek = _findFirstDayOfWeek(DateTime.now());
      _loadSchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мое расписание'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildWeekNavigation(),
          Expanded(
            child: FutureBuilder<List<ScheduleModel>>(
              future: _scheduleFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final grouped = _groupLessonsByDate(snapshot.data!);
                final sortedDates = grouped.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final lessons = grouped[date]!;
                    return _buildDaySection(date, lessons);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigation() {
    final rangeFormat = DateFormat('dd.MM');
    final endOfWeek = _startOfWeek.add(const Duration(days: 6));
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        children: [
          Text(
            '${rangeFormat.format(_startOfWeek)} — ${rangeFormat.format(endOfWeek)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => _changeWeek(-1),
              ),
              ElevatedButton.icon(
                onPressed: _resetToCurrentWeek,
                icon: const Icon(Icons.today),
                label: const Text('Текущая'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade100,
                  foregroundColor: Colors.orange.shade900,
                  elevation: 0,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 20),
                onPressed: () => _changeWeek(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<ScheduleModel>> _groupLessonsByDate(List<ScheduleModel> lessons) {
    final Map<DateTime, List<ScheduleModel>> grouped = {};
    
    for (var lesson in lessons) {
      final dateKey = DateTime(lesson.date.year, lesson.date.month, lesson.date.day);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(lesson);
    }
    
    grouped.forEach((key, list) {
      list.sort((a, b) => a.pairNumber.compareTo(b.pairNumber));
    });
    
    return grouped;
  }

  Widget _buildDaySection(DateTime date, List<ScheduleModel> lessons) {
    final now = DateTime.now();
    final isToday = date.year == now.year && 
                    date.month == now.month && 
                    date.day == now.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
          child: Text(
            DateFormat('EEEE, d MMMM', 'ru').format(date).toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.orange : Colors.grey.shade700,
              fontSize: 13,
              letterSpacing: 1.1,
            ),
          ),
        ),
        ...lessons.map((l) => _buildLessonCard(l)).toList(),
      ],
    );
  }

  Widget _buildLessonCard(ScheduleModel lesson) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${lesson.pairNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 18),
            ),
          ),
        ),
        title: Text(
          lesson.subjectName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson.timeRange),
            const SizedBox(height: 2),
            Text(
              lesson.teacherFullName,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceScreen(
                subjectId: lesson.subjectId,
                subjectName: lesson.subjectName,
                groupId: lesson.groupId,
                scheduleItemId: lesson.scheduleItemId,
                teacherId: widget.teacherId,
                date: lesson.date,
                pairNumber: lesson.pairNumber,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'На этой неделе занятий не найдено',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}