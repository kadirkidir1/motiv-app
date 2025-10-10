import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/daily_task.dart';
import 'routine_detail_screen.dart';
import 'daily_record_screen.dart';
import '../services/language_service.dart';
import '../services/database_service.dart';
import '../services/subscription_service.dart';
import 'premium_screen.dart';

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
  List<DailyTask> dailyTasks = [];
  bool isLoadingTasks = true;
  Map<String, int> todayProgress = {'total': 0, 'completed': 0, 'remaining': 0};
  Map<String, double> weeklyStats = {'successRate': 0.0, 'totalMinutes': 0.0, 'streak': 0.0};
  Map<String, double> motivationProgress = {};

  @override
  void initState() {
    super.initState();
    _loadDailyTasks();
    _loadTodayProgress();
    _loadWeeklyStats();
    _loadMotivationProgress();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motivations.length != widget.motivations.length) {
      _loadTodayProgress();
      _loadWeeklyStats();
      _loadMotivationProgress();
    }
  }

  Future<void> _loadDailyTasks() async {
    try {
      final tasks = await DatabaseService.getDailyTasks();
      setState(() {
        dailyTasks = tasks;
        isLoadingTasks = false;
      });
    } catch (e) {
      setState(() {
        isLoadingTasks = false;
      });
    }
  }

  Future<void> _loadTodayProgress() async {
    try {
      final progress = await _getTodayProgressFromDatabase();
      setState(() {
        todayProgress = progress;
      });
    } catch (e) {
      // Keep default values on error
    }
  }

  Future<void> _loadWeeklyStats() async {
    try {
      final stats = await _getWeeklyStatsFromDatabase();
      setState(() {
        weeklyStats = stats;
      });
    } catch (e) {
      // Keep default values on error
    }
  }

  Future<void> _loadMotivationProgress() async {
    final progressMap = <String, double>{};
    
    for (final motivation in widget.motivations) {
      final progress = await _calculateMotivationProgress(motivation);
      progressMap[motivation.id] = progress;
    }
    
    setState(() {
      motivationProgress = progressMap;
    });
  }

  Future<double> _calculateMotivationProgress(Routine motivation) async {
    final now = DateTime.now();
    final daysSinceCreation = now.difference(motivation.createdAt).inDays;
    
    if (daysSinceCreation < 1) {
      return 0.0;
    }

    final notes = await DatabaseService.getDailyNotes(motivation.id);
    // Sadece not girilmiş günleri say (boş not olmamalı)
    final completedDays = notes.where((note) => note.note.trim().isNotEmpty).length;

    if (motivation.frequency == RoutineFrequency.daily) {
      final expectedDays = daysSinceCreation;
      return expectedDays > 0 ? (completedDays / expectedDays) * 100 : 0.0;
    } else if (motivation.frequency == RoutineFrequency.weekly) {
      final expectedWeeks = (daysSinceCreation / 7).ceil();
      if (expectedWeeks == 0) return 0.0;
      return (completedDays / expectedWeeks) * 100;
    } else {
      final expectedMonths = (daysSinceCreation / 30).ceil();
      if (expectedMonths == 0) return 0.0;
      return (completedDays / expectedMonths) * 100;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildDailyTasksOverview(),
            const SizedBox(height: 20),
            _buildMotivationGrid(),
            const SizedBox(height: 20),
            _buildTodayOverview(todayProgress),
            const SizedBox(height: 20),
            FutureBuilder<bool>(
              future: SubscriptionService.isPremium(),
              builder: (context, snapshot) {
                final isPremium = snapshot.data ?? false;
                if (!isPremium) {
                  return _buildPremiumFeatureCard();
                }
                return Column(
                  children: [
                    _buildWeeklyStats(weeklyStats),
                    const SizedBox(height: 20),
                    _buildCalendarWidget(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final now = DateTime.now();
    final greeting = _getGreeting();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${now.day} ${_getMonthName(now.month)} ${now.year}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.get('welcome_message', widget.languageCode),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOverview(Map<String, int> todayProgress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.get('today_summary', widget.languageCode),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTodayStatCard(
                    AppLocalizations.get('completed', widget.languageCode),
                    '${todayProgress['completed']}',
                    '${todayProgress['total']}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTodayStatCard(
                    AppLocalizations.get('remaining', widget.languageCode),
                    '${todayProgress['remaining']}',
                    '${todayProgress['total']}',
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatCard(String title, String value, String total, IconData icon, Color color) {
    return InkWell(
      onTap: () => _showTodaySummaryDetails(title, value, total, color),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              '$value/$total',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTasksOverview() {
    if (isLoadingTasks) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final activeTasks = dailyTasks.where((task) => task.isActive).toList();
    final completedTasks = dailyTasks.where((task) => task.status == TaskStatus.completed).toList();
    final expiredTasks = dailyTasks.where((task) => task.isExpired).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.get('daily_tasks', widget.languageCode),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${dailyTasks.length} ${dailyTasks.length == 1 ? AppLocalizations.get('task', widget.languageCode) : AppLocalizations.get('tasks', widget.languageCode)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (dailyTasks.isEmpty)
              Center(
                child: Text(
                  AppLocalizations.get('no_daily_tasks', widget.languageCode),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildTaskStatCard(
                      AppLocalizations.get('active', widget.languageCode),
                      activeTasks.length.toString(),
                      Icons.schedule,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTaskStatCard(
                      AppLocalizations.get('completed', widget.languageCode),
                      completedTasks.length.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTaskStatCard(
                      AppLocalizations.get('expired', widget.languageCode),
                      expiredTasks.length.toString(),
                      Icons.cancel,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            if (activeTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                AppLocalizations.get('upcoming_tasks', widget.languageCode),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...activeTasks.take(3).map((task) => _buildTaskPreview(task)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatCard(String title, String value, IconData icon, Color color) {
    return InkWell(
      onTap: () => _showTaskSummaryDetails(title, value, color),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskPreview(DailyTask task) {
    final timeLeft = task.expiresAt.difference(DateTime.now());
    String timeText;
    
    if (timeLeft.inHours > 0) {
      timeText = '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m';
    } else if (timeLeft.inMinutes > 0) {
      timeText = '${timeLeft.inMinutes}m';
    } else {
      timeText = AppLocalizations.get('expired', widget.languageCode);
    }

    return InkWell(
      onTap: () => _showTaskDetails(task),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.task_alt,
              color: Colors.blue.shade600,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              timeText,
              style: TextStyle(
                fontSize: 11,
                color: timeLeft.isNegative ? Colors.red : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetails(DailyTask task) {
    final timeLeft = task.expiresAt.difference(DateTime.now());
    String statusText;
    Color statusColor;
    
    if (task.status == TaskStatus.completed) {
      statusText = AppLocalizations.get('completed', widget.languageCode);
      statusColor = Colors.green;
    } else if (timeLeft.isNegative) {
      statusText = AppLocalizations.get('expired', widget.languageCode);
      statusColor = Colors.red;
    } else {
      statusText = AppLocalizations.get('active', widget.languageCode);
      statusColor = Colors.blue;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.task_alt, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (task.description != null && task.description!.isNotEmpty) ...[
              Text(
                AppLocalizations.get('description', widget.languageCode),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                task.description!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${AppLocalizations.get('created', widget.languageCode)}: ${_formatDate(task.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  timeLeft.isNegative ? Icons.error : Icons.timer,
                  size: 16,
                  color: timeLeft.isNegative ? Colors.red : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${AppLocalizations.get('expires', widget.languageCode)}: ${_formatDate(task.expiresAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: timeLeft.isNegative ? Colors.red : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.get('close', widget.languageCode)),
          ),
          if (task.status == TaskStatus.pending) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddNoteDialog(task);
              },
              child: Text(AppLocalizations.get('add_note', widget.languageCode)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _completeTaskFromDashboard(task);
              },
              child: Text(AppLocalizations.get('complete', widget.languageCode)),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showTodaySummaryDetails(String title, String value, String total, Color color) async {
    final isCompleted = title.contains(AppLocalizations.get('completed', widget.languageCode));
    
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final List<Routine> relevantMotivations = [];
    
    for (final motivation in widget.motivations) {
      final notes = await DatabaseService.getDailyNotes(motivation.id);
      bool hasCompletedToday = false;
      
      for (final note in notes) {
        final noteDate = note.date;
        if (noteDate.isAfter(todayStart) && noteDate.isBefore(todayEnd)) {
          final minutes = await _getMinutesForNote(note.id);
          if (minutes >= motivation.targetMinutes) {
            hasCompletedToday = true;
            break;
          }
        }
      }
      
      if (isCompleted && hasCompletedToday) {
        relevantMotivations.add(motivation);
      } else if (!isCompleted && !hasCompletedToday) {
        relevantMotivations.add(motivation);
      }
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(isCompleted ? Icons.check_circle : Icons.pending, color: color),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '$value/$total',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${((int.parse(value) / int.parse(total)) * 100).round()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted 
                ? AppLocalizations.get('completed_motivations_today', widget.languageCode)
                : AppLocalizations.get('remaining_motivations_today', widget.languageCode),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (relevantMotivations.isNotEmpty) ...[
              ...relevantMotivations.take(5).map((motivation) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(motivation.category),
                      size: 16,
                      color: _getCategoryColor(motivation.category),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            motivation.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (motivation.targetMinutes > 0)
                            Text(
                              '${AppLocalizations.get('target', widget.languageCode)}: ${motivation.targetMinutes} ${AppLocalizations.get('minutes', widget.languageCode)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCompleted ? '✓' : '○',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              if (relevantMotivations.length > 5)
                Text(
                  '+${relevantMotivations.length - 5} ${AppLocalizations.get('more', widget.languageCode)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ] else
              Text(
                AppLocalizations.get('no_motivations_added_yet', widget.languageCode),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.get('close', widget.languageCode)),
          ),
        ],
      ),
    );
  }

  void _showTaskSummaryDetails(String title, String value, Color color) {
    List<DailyTask> relevantTasks;
    String description;
    
    if (title.contains(AppLocalizations.get('active', widget.languageCode))) {
      relevantTasks = dailyTasks.where((task) => task.isActive).toList();
      description = AppLocalizations.get('tasks_in_progress', widget.languageCode);
    } else if (title.contains(AppLocalizations.get('completed', widget.languageCode))) {
      relevantTasks = dailyTasks.where((task) => task.status == TaskStatus.completed).toList();
      description = AppLocalizations.get('completed_tasks_today', widget.languageCode);
    } else {
      relevantTasks = dailyTasks.where((task) => task.isExpired).toList();
      description = AppLocalizations.get('expired_tasks', widget.languageCode);
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              title.contains('Active') ? Icons.schedule :
              title.contains('Completed') ? Icons.check_circle : Icons.cancel,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.get('tasks', widget.languageCode),
                    style: TextStyle(
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            if (relevantTasks.isNotEmpty) ...[
              ...relevantTasks.take(4).map((task) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (task.isActive)
                      Text(
                        _getTimeLeft(task.expiresAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              )),
              if (relevantTasks.length > 4)
                Text(
                  '+${relevantTasks.length - 4} ${AppLocalizations.get('more', widget.languageCode)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ] else
              Text(
                AppLocalizations.get('no_tasks_in_category', widget.languageCode),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.get('close', widget.languageCode)),
          ),
        ],
      ),
    );
  }

  String _getTimeLeft(DateTime expiresAt) {
    final timeLeft = expiresAt.difference(DateTime.now());
    if (timeLeft.inHours > 0) {
      return '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m';
    } else if (timeLeft.inMinutes > 0) {
      return '${timeLeft.inMinutes}m';
    } else {
      return AppLocalizations.get('expired', widget.languageCode);
    }
  }

  void _showAddNoteDialog(DailyTask task) {
    final noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.get('add_note', widget.languageCode)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppLocalizations.get('task', widget.languageCode)}: ${task.title}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: AppLocalizations.get('note', widget.languageCode),
                hintText: AppLocalizations.get('add_note_hint', widget.languageCode),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.get('cancel', widget.languageCode)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveTaskNote(task, noteController.text);
            },
            child: Text(AppLocalizations.get('save', widget.languageCode)),
          ),
        ],
      ),
    );
  }

  void _saveTaskNote(DailyTask task, String note) async {
    if (note.trim().isEmpty) return;
    
    final messenger = ScaffoldMessenger.of(context);
    final noteAddedText = AppLocalizations.get('note_added', widget.languageCode);
    final errorText = AppLocalizations.get('error_occurred', widget.languageCode);
    
    // Not'u task açıklamasına ekle
    final updatedDescription = task.description != null 
        ? '${task.description}\n\n${AppLocalizations.get('note', widget.languageCode)}: $note'
        : '${AppLocalizations.get('note', widget.languageCode)}: $note';
    
    final updatedTask = task.copyWith(description: updatedDescription);
    
    try {
      await DatabaseService.updateDailyTask(updatedTask);
      setState(() {
        final index = dailyTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          dailyTasks[index] = updatedTask;
        }
      });
      
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(noteAddedText)));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(errorText)));
      }
    }
  }

  void _completeTaskFromDashboard(DailyTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.get('complete_task', widget.languageCode)),
        content: Text(AppLocalizations.get('mark_task_complete_question', widget.languageCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.get('cancel', widget.languageCode)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final completedTask = task.copyWith(
                status: TaskStatus.completed,
                addToCalendar: false,
              );
              
              final messenger = ScaffoldMessenger.of(context);
              final completedText = AppLocalizations.get('task_completed', widget.languageCode);
              final errorText = AppLocalizations.get('error_occurred', widget.languageCode);
              
              try {
                await DatabaseService.updateDailyTask(completedTask);
                setState(() {
                  final index = dailyTasks.indexWhere((t) => t.id == task.id);
                  if (index != -1) {
                    dailyTasks[index] = completedTask;
                  }
                });
                
                if (mounted) {
                  messenger.showSnackBar(SnackBar(content: Text(completedText)));
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(SnackBar(content: Text(errorText)));
                }
              }
            },
            child: Text(AppLocalizations.get('complete', widget.languageCode)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStats(Map<String, double> weeklyStats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.get('this_week', widget.languageCode),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeeklyStatItem(
                  AppLocalizations.get('success_rate', widget.languageCode),
                  '${weeklyStats['successRate']?.round()}%',
                  Icons.trending_up,
                  Colors.blue,
                ),
                _buildWeeklyStatItem(
                  AppLocalizations.get('total_time', widget.languageCode),
                  '${weeklyStats['totalMinutes']?.round()} ${AppLocalizations.get('minutes', widget.languageCode)}',
                  Icons.timer,
                  Colors.purple,
                ),
                _buildWeeklyStatItem(
                  widget.languageCode == 'tr' ? 'Seri' : 'Streak',
                  '${weeklyStats['streak']?.round()} ${AppLocalizations.get('days', widget.languageCode)}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.get('my_motivations', widget.languageCode),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: widget.motivations.length,
          itemBuilder: (context, index) {
            final motivation = widget.motivations[index];
            return _buildMotivationCard(motivation);
          },
        ),
      ],
    );
  }

  Widget _buildMotivationCard(Routine motivation) {
    final progress = _getMotivationProgress(motivation);
    
    return Card(
      child: InkWell(
        onTap: () {
          _showMotivationOptions(motivation);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getCategoryColor(motivation.category),
                    radius: 16,
                    child: Icon(
                      _getCategoryIcon(motivation.category),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: progress > 70 ? Colors.green : progress > 40 ? Colors.orange : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${progress.round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                motivation.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(
                  progress > 70 ? Colors.green : progress > 40 ? Colors.orange : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarWidget() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.languageCode == 'tr' ? 'Takvim' : 'Calendar',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_getMonthName(now.month)} ${now.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
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
            FutureBuilder<Map<String, bool>>(
              future: _getCalendarData(),
              builder: (context, snapshot) {
                final calendarData = snapshot.data ?? {};
                return GridView.builder(
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
                    final hasActivity = calendarData[dateKey] ?? false;
                    final isToday = now.year == date.year &&
                        now.month == date.month &&
                        now.day == date.day;

                    return GestureDetector(
                      onTap: () => _showDayDetails(date),
                      child: Container(
                        decoration: BoxDecoration(
                          color: hasActivity ? Colors.green.shade100 : null,
                          border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, bool>> _getCalendarData() async {
    final Map<String, bool> calendarData = {};
    
    for (final motivation in widget.motivations) {
      final notes = await DatabaseService.getDailyNotes(motivation.id);
      for (final note in notes) {
        final dateKey = '${note.date.year}-${note.date.month}-${note.date.day}';
        calendarData[dateKey] = true;
      }
    }
    
    return calendarData;
  }

  void _showDayDetails(DateTime date) async {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    final List<String> motivationNotes = [];
    
    for (final motivation in widget.motivations) {
      final notes = await DatabaseService.getDailyNotes(motivation.id);
      for (final note in notes) {
        final noteKey = '${note.date.year}-${note.date.month}-${note.date.day}';
        if (noteKey == dateKey) {
          motivationNotes.add('${motivation.title}: ${note.note}');
        }
      }
    }
    
    final dayTasks = dailyTasks.where((task) {
      final taskDate = task.expiresAt;
      return taskDate.year == date.year && taskDate.month == date.month && taskDate.day == date.day;
    }).toList();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${date.day} ${_getMonthName(date.month)} ${date.year}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (motivationNotes.isEmpty && dayTasks.isEmpty)
                Text(
                  widget.languageCode == 'tr' ? 'Bu gün için aktivite yok' : 'No activities',
                  style: TextStyle(color: Colors.grey.shade600),
                )
              else ...[
                if (motivationNotes.isNotEmpty) ...[
                  Text(
                    widget.languageCode == 'tr' ? 'Motivasyonlar' : 'Motivations',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...motivationNotes.map((note) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(note, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                ],
                if (dayTasks.isNotEmpty) ...[
                  Text(
                    widget.languageCode == 'tr' ? 'Görevler' : 'Tasks',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...dayTasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          task.status == TaskStatus.completed ? Icons.check_circle : Icons.schedule,
                          color: task.status == TaskStatus.completed ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(task.title, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.get('close', widget.languageCode)),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _getTodayProgressFromDatabase() async {
    final total = widget.motivations.length;
    if (total == 0) {
      return {'total': 0, 'completed': 0, 'remaining': 0};
    }

    int completed = 0;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    for (final motivation in widget.motivations) {
      final notes = await DatabaseService.getDailyNotes(motivation.id);
      
      for (final note in notes) {
        final noteDate = note.date;
        if (noteDate.isAfter(todayStart) && noteDate.isBefore(todayEnd)) {
          final minutes = await _getMinutesForNote(note.id);
          if (minutes >= motivation.targetMinutes) {
            completed++;
            break;
          }
        }
      }
    }

    return {
      'total': total,
      'completed': completed,
      'remaining': total - completed,
    };
  }

  Future<Map<String, double>> _getWeeklyStatsFromDatabase() async {
    if (widget.motivations.isEmpty) {
      return {'successRate': 0.0, 'totalMinutes': 0.0, 'streak': 0.0};
    }

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEnd = weekStartDate.add(const Duration(days: 7));

    int totalExpected = 0;
    int totalCompleted = 0;
    double totalMinutes = 0;
    int consecutiveDays = 0;

    for (final motivation in widget.motivations) {
      final notes = await DatabaseService.getDailyNotes(motivation.id);
      
      final weekNotes = notes.where((note) {
        return note.date.isAfter(weekStartDate) && note.date.isBefore(weekEnd);
      }).toList();

      if (motivation.frequency == RoutineFrequency.daily) {
        totalExpected += now.weekday;
        totalCompleted += weekNotes.length;
        totalMinutes += (weekNotes.length * motivation.targetMinutes).toDouble();
      } else if (motivation.frequency == RoutineFrequency.weekly) {
        totalExpected += 1;
        if (weekNotes.isNotEmpty) {
          totalCompleted += 1;
          totalMinutes += motivation.targetMinutes.toDouble();
        }
      }

      final allNotes = notes..sort((a, b) => b.date.compareTo(a.date));
      int currentStreak = 0;
      DateTime? lastDate;
      
      for (final note in allNotes) {
        if (lastDate == null) {
          lastDate = note.date;
          currentStreak = 1;
        } else {
          final diff = lastDate.difference(note.date).inDays;
          if (diff == 1) {
            currentStreak++;
            lastDate = note.date;
          } else {
            break;
          }
        }
      }
      
      if (currentStreak > consecutiveDays) {
        consecutiveDays = currentStreak;
      }
    }

    final successRate = totalExpected > 0 ? (totalCompleted / totalExpected) * 100 : 0.0;

    return {
      'successRate': successRate,
      'totalMinutes': totalMinutes,
      'streak': consecutiveDays.toDouble(),
    };
  }

  double _getMotivationProgress(Routine motivation) {
    return (motivationProgress[motivation.id] ?? 0.0).clamp(0.0, 100.0);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppLocalizations.get('welcome_morning', widget.languageCode);
    return AppLocalizations.get('welcome_afternoon', widget.languageCode);
  }



  String _getMonthName(int month) {
    final monthsTr = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final monthsEn = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return widget.languageCode == 'en' ? monthsEn[month] : monthsTr[month];
  }

  Color _getCategoryColor(RoutineCategory category) {
    switch (category) {
      case RoutineCategory.spiritual:
        return Colors.green.shade600;
      case RoutineCategory.education:
        return Colors.blue.shade600;
      case RoutineCategory.health:
        return Colors.orange.shade600;
      case RoutineCategory.household:
        return Colors.brown.shade600;
      case RoutineCategory.selfCare:
        return Colors.pink.shade600;
      case RoutineCategory.social:
        return Colors.teal.shade600;
      case RoutineCategory.hobby:
        return Colors.indigo.shade600;
      case RoutineCategory.career:
        return Colors.deepOrange.shade600;
      case RoutineCategory.personal:
        return Colors.purple.shade600;
    }
  }

  IconData _getCategoryIcon(RoutineCategory category) {
    switch (category) {
      case RoutineCategory.spiritual:
        return Icons.mosque;
      case RoutineCategory.education:
        return Icons.school;
      case RoutineCategory.health:
        return Icons.health_and_safety;
      case RoutineCategory.household:
        return Icons.home;
      case RoutineCategory.selfCare:
        return Icons.spa;
      case RoutineCategory.social:
        return Icons.people;
      case RoutineCategory.hobby:
        return Icons.palette;
      case RoutineCategory.career:
        return Icons.work;
      case RoutineCategory.personal:
        return Icons.person;
    }
  }



  Future<int> _getMinutesForNote(String noteId) async {
    final db = await DatabaseService.database;
    final result = await db.query(
      'daily_notes',
      columns: ['minutesSpent'],
      where: 'id = ?',
      whereArgs: [noteId],
    );
    
    if (result.isNotEmpty) {
      return result.first['minutesSpent'] as int? ?? 0;
    }
    return 0;
  }

  Widget _buildPremiumFeatureCard() {
    final isTurkish = widget.languageCode == 'tr';
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PremiumScreen(languageCode: widget.languageCode),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.workspace_premium, size: 48, color: Colors.amber.shade700),
              const SizedBox(height: 12),
              Text(
                isTurkish ? 'Premium Özellikler' : 'Premium Features',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isTurkish
                    ? 'Detaylı istatistikler ve takvim görünümü için Premium\'a geçin'
                    : 'Upgrade to Premium for detailed statistics and calendar view',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PremiumScreen(languageCode: widget.languageCode),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                ),
                child: Text(
                  isTurkish ? 'Premium\'a Geç' : 'Go Premium',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMotivationOptions(Routine motivation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.add_circle, color: Colors.green.shade600),
              title: Text(AppLocalizations.get('create_daily_record', widget.languageCode)),
              subtitle: Text(AppLocalizations.get('did_you_do_today', widget.languageCode)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DailyRecordScreen(
                      motivation: motivation,
                      languageCode: widget.languageCode,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: Colors.blue.shade600),
              title: Text(AppLocalizations.get('view_details', widget.languageCode)),
              subtitle: Text(AppLocalizations.get('statistics_progress', widget.languageCode)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MotivationDetailScreen(motivation: motivation),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}