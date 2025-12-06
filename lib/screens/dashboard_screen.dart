import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/daily_task.dart';
import 'routine_detail_screen.dart';
import 'daily_record_screen.dart';
import '../services/tracking_service.dart';
import '../services/database_service.dart';

class DashboardScreen extends StatefulWidget {
  final List<Routine> motivations;
  final String languageCode;

  const DashboardScreen({
    super.key,
    required this.motivations,
    required this.languageCode,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, bool> todayCompletions = {};
  int currentStreak = 0;
  List<DailyTask> activeTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final completions = <String, bool>{};
    int maxStreak = 0;

    for (final routine in widget.motivations) {
      final isCompleted = await TrackingService.isCompletedToday(routine.id);
      completions[routine.id] = isCompleted;
      
      final streak = await TrackingService.calculateStreak(routine.id);
      if (streak > maxStreak) maxStreak = streak;
    }

    final tasks = await DatabaseService.getDailyTasks();
    final active = tasks.where((t) => t.isActive).toList();

    setState(() {
      todayCompletions = completions;
      currentStreak = maxStreak;
      activeTasks = active;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedCount = todayCompletions.values.where((v) => v).length;
    final totalCount = widget.motivations.length;

    return Scaffold(
      body: widget.motivations.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Tarih ve Selamlaşma
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getFormattedDate(),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Bugünün İlerlemesi - Minimal
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.languageCode == 'tr' ? 'Bugün' : 'Today',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$completedCount',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ' / $totalCount',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '🔥',
                            style: TextStyle(fontSize: 28),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$currentStreak',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.languageCode == 'tr' ? 'gün' : 'days',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Günlük Görevler
                if (activeTasks.isNotEmpty) ...[
                  Text(
                    widget.languageCode == 'tr' ? 'Günlük Görevler' : 'Daily Tasks',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...activeTasks.take(3).map((task) => _buildTaskItem(task)),
                  const SizedBox(height: 32),
                ],

                // Rutinler Listesi - Defter Gibi
                Text(
                  widget.languageCode == 'tr' ? 'Rutinlerim' : 'My Routines',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                ...widget.motivations.map((routine) {
                  final isCompleted = todayCompletions[routine.id] ?? false;
                  return _buildRoutineItem(routine, isCompleted);
                }),
              ],
            ),
    );
  }

  Widget _buildTaskItem(DailyTask task) {
    final timeLeft = task.expiresAt.difference(DateTime.now());
    String timeText;
    if (timeLeft.inHours > 0) {
      timeText = '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m';
    } else if (timeLeft.inMinutes > 0) {
      timeText = '${timeLeft.inMinutes}m';
    } else {
      timeText = widget.languageCode == 'tr' ? 'Süresi doldu' : 'Expired';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.task_alt,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 13,
                    color: timeLeft.isNegative ? Colors.red : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineItem(Routine routine, bool isCompleted) {
    return GestureDetector(
      onTap: () => _handleRoutineTap(routine, isCompleted),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color: isCompleted 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.transparent,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Rutin Bilgisi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Colors.grey.shade600 : null,
                    ),
                  ),
                  if (routine.targetMinutes > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${routine.targetMinutes} ${widget.languageCode == 'tr' ? 'dk' : 'min'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Sağ Ok
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            widget.languageCode == 'tr' 
                ? 'Henüz rutin eklemediniz' 
                : 'No routines yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.languageCode == 'tr'
                ? 'İlk rutininizi eklemek için + butonuna tıklayın'
                : 'Tap + to add your first routine',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleRoutineTap(Routine routine, bool isCompleted) {
    if (isCompleted) {
      // Tamamlanmışsa detay ekranına git
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MotivationDetailScreen(motivation: routine),
        ),
      );
    } else {
      // Tamamlanmamışsa kayıt ekranına git
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DailyRecordScreen(
            motivation: routine,
            languageCode: widget.languageCode,
          ),
        ),
      ).then((_) => _loadTodayData());
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (widget.languageCode == 'tr') {
      if (hour < 12) return 'Günaydın';
      if (hour < 18) return 'İyi günler';
      return 'İyi akşamlar';
    } else {
      if (hour < 12) return 'Good morning';
      if (hour < 18) return 'Good afternoon';
      return 'Good evening';
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = widget.languageCode == 'tr'
        ? ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
           'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık']
        : ['January', 'February', 'March', 'April', 'May', 'June',
           'July', 'August', 'September', 'October', 'November', 'December'];
    
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
