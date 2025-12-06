import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/daily_task.dart';
import '../models/daily_note.dart';
import '../services/database_service.dart';
import '../services/language_service.dart';

class CalendarScreen extends StatefulWidget {
  final List<Routine> motivations;
  final String languageCode;

  const CalendarScreen({
    super.key,
    required this.motivations,
    required this.languageCode,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, List<DailyNote>> notesByDate = {};
  List<DailyTask> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    // Tüm notları al (silinmiş motivasyonlar dahil)
    final db = await DatabaseService.database;
    final notesResult = await db.query('daily_notes', orderBy: 'date DESC');
    final allNotes = notesResult.map((map) {
      final id = map['id']?.toString() ?? '';
      final routineId = map['routineId']?.toString() ?? '';
      final dateStr = map['date']?.toString() ?? DateTime.now().toIso8601String();
      final note = map['note']?.toString() ?? '';
      final mood = (map['mood'] ?? 3) as int;
      final tagsStr = map['tags']?.toString() ?? '';
      
      return DailyNote(
        id: id,
        routineId: routineId,
        date: DateTime.parse(dateStr),
        note: note,
        mood: mood,
        tags: tagsStr.isNotEmpty ? tagsStr.split(',') : [],
      );
    }).toList();

    final tasksList = await DatabaseService.getDailyTasks();

    final Map<String, List<DailyNote>> groupedNotes = {};
    for (final note in allNotes) {
      final key = '${note.date.year}-${note.date.month}-${note.date.day}';
      groupedNotes.putIfAbsent(key, () => []).add(note);
    }

    setState(() {
      notesByDate = groupedNotes;
      tasks = tasksList;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('calendar', widget.languageCode)),
        backgroundColor: Colors.green.shade300,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendar(),
                _buildSelectedDateDetails(),
              ],
            ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${_getMonthName(now.month)} ${now.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: (widget.languageCode == 'tr'
                  ? ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
                  : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                  .map((day) => SizedBox(
                        width: 40,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: startWeekday - 1 + daysInMonth,
              itemBuilder: (context, index) {
                if (index < startWeekday - 1) {
                  return const SizedBox();
                }

                final day = index - startWeekday + 2;
                final date = DateTime(now.year, now.month, day);
                final dateKey = '${date.year}-${date.month}-${date.day}';
                final hasNotes = notesByDate.containsKey(dateKey);
                final isSelected = selectedDate.year == date.year &&
                    selectedDate.month == date.month &&
                    selectedDate.day == date.day;
                final isToday = now.year == date.year &&
                    now.month == date.month &&
                    now.day == date.day;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade600
                          : hasNotes
                              ? Colors.green.shade100
                              : null,
                      border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateDetails() {
    final dateKey = '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}';
    final notes = notesByDate[dateKey] ?? [];
    final dayTasks = tasks.where((task) {
      final taskDate = task.expiresAt;
      return taskDate.year == selectedDate.year &&
          taskDate.month == selectedDate.month &&
          taskDate.day == selectedDate.day;
    }).toList();

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
              if (notes.isNotEmpty) ...[
                Text(
                  AppLocalizations.get('motivations', widget.languageCode),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...notes.map((note) {
                  Routine? motivation;
                  try {
                    motivation = widget.motivations.firstWhere((m) => m.id == note.routineId);
                  } catch (e) {
                    motivation = null;
                  }
                  
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: motivation != null ? _getCategoryColor(motivation.category) : Colors.grey,
                        child: Icon(
                          motivation != null ? _getCategoryIcon(motivation.category) : Icons.note,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(motivation?.title ?? (widget.languageCode == 'tr' ? 'Silinmiş Motivasyon' : 'Deleted Routine')),
                      subtitle: Text(note.note ?? ''),
                      trailing: Text(_getMoodEmoji(note.mood), style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }),
              ],
              if (dayTasks.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.get('tasks', widget.languageCode),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...dayTasks.map((task) => Card(
                      child: ListTile(
                        leading: Icon(
                          task.status == TaskStatus.completed ? Icons.check_circle : Icons.schedule,
                          color: task.status == TaskStatus.completed ? Colors.green : Colors.orange,
                        ),
                        title: Text(task.title),
                        subtitle: task.description != null ? Text(task.description!) : null,
                      ),
                    )),
              ],
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    final monthsTr = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    final monthsEn = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return widget.languageCode == 'en' ? monthsEn[month] : monthsTr[month];
  }

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1: return '😢';
      case 2: return '🙁';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😄';
      default: return '😐';
    }
  }

  Color _getCategoryColor(RoutineCategory category) {
    switch (category) {
      case RoutineCategory.spiritual: return Colors.green.shade600;
      case RoutineCategory.education: return Colors.blue.shade600;
      case RoutineCategory.health: return Colors.orange.shade600;
      case RoutineCategory.household: return Colors.brown.shade600;
      case RoutineCategory.selfCare: return Colors.pink.shade600;
      case RoutineCategory.social: return Colors.teal.shade600;
      case RoutineCategory.hobby: return Colors.indigo.shade600;
      case RoutineCategory.career: return Colors.deepOrange.shade600;
      case RoutineCategory.personal: return Colors.purple.shade600;
    }
  }

  IconData _getCategoryIcon(RoutineCategory category) {
    switch (category) {
      case RoutineCategory.spiritual: return Icons.mosque;
      case RoutineCategory.education: return Icons.school;
      case RoutineCategory.health: return Icons.health_and_safety;
      case RoutineCategory.household: return Icons.home;
      case RoutineCategory.selfCare: return Icons.spa;
      case RoutineCategory.social: return Icons.people;
      case RoutineCategory.hobby: return Icons.palette;
      case RoutineCategory.career: return Icons.work;
      case RoutineCategory.personal: return Icons.person;
    }
  }
}
