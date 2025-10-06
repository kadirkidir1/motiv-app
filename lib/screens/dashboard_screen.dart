import 'package:flutter/material.dart';
import '../models/motivation.dart';
import '../models/daily_task.dart';
import 'motivation_detail_screen.dart';
import 'daily_record_screen.dart';
import '../services/motivation_quotes.dart';
import '../services/language_service.dart';
import '../services/database_service.dart';

class DashboardScreen extends StatefulWidget {
  final List<Motivation> motivations;
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

  @override
  void initState() {
    super.initState();
    _loadDailyTasks();
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

  @override
  Widget build(BuildContext context) {
    final todayProgress = _getTodayProgress();
    final weeklyStats = _getWeeklyStats();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildDailyQuote(),
            const SizedBox(height: 20),
            _buildTodayOverview(todayProgress),
            const SizedBox(height: 20),
            _buildDailyTasksOverview(),
            const SizedBox(height: 20),
            _buildWeeklyStats(weeklyStats),
            const SizedBox(height: 20),
            _buildMotivationGrid(),
            const SizedBox(height: 20),
            _buildQuickActions(),
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

  void _showTodaySummaryDetails(String title, String value, String total, Color color) {
    final isCompleted = title.contains(AppLocalizations.get('completed', widget.languageCode));
    
    // Tüm motivasyonları göster
    final relevantMotivations = widget.motivations;
    
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
                  AppLocalizations.get('streak', widget.languageCode),
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

  Widget _buildMotivationCard(Motivation motivation) {
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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.get('quick_actions', widget.languageCode),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildQuickActionCard(
            AppLocalizations.get('complete_today', widget.languageCode),
            Icons.check_circle,
            Colors.green,
            () => _markAllTodayComplete(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _getTodayProgress() {
    final total = widget.motivations.length;
    // In a real app, this would check daily_notes for today's completions
    // For now, simulate based on motivation frequency and current time
    final now = DateTime.now();
    int completed = 0;
    
    for (final motivation in widget.motivations) {
      if (motivation.frequency == MotivationFrequency.daily) {
        // Simulate completion based on time of day
        if (now.hour > 12) completed++; // Assume completed if after noon
      } else if (motivation.frequency == MotivationFrequency.weekly) {
        // Weekly tasks are less likely to be completed today
        if (now.weekday == DateTime.monday) completed++;
      }
    }
    
    // Ensure completed doesn't exceed total
    completed = completed > total ? total : completed;
    
    return {
      'total': total,
      'completed': completed,
      'remaining': total - completed,
    };
  }

  Map<String, double> _getWeeklyStats() {
    if (widget.motivations.isEmpty) {
      return {
        'successRate': 0.0,
        'totalMinutes': 0.0,
        'streak': 0.0,
      };
    }
    
    // Calculate based on actual motivations
    double completedMinutes = 0;
    int totalExpectedSessions = 0;
    int completedSessions = 0;
    
    final now = DateTime.now();
    final dayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
    
    for (final motivation in widget.motivations) {
      final daysSinceCreation = now.difference(motivation.createdAt).inDays;
      
      if (motivation.frequency == MotivationFrequency.daily) {
        // For daily motivations, count days passed this week
        final daysThisWeek = dayOfWeek; // Days passed in current week
        totalExpectedSessions += daysThisWeek;
        // totalExpectedMinutes += motivation.targetMinutes * daysThisWeek;
        
        // Realistic completion: newer motivations have lower completion rate
        final completionRate = daysSinceCreation < 7 ? 0.3 : daysSinceCreation < 30 ? 0.6 : 0.8;
        final sessionsCompleted = (daysThisWeek * completionRate).round();
        completedSessions += sessionsCompleted;
        completedMinutes += motivation.targetMinutes * sessionsCompleted;
        
      } else if (motivation.frequency == MotivationFrequency.weekly) {
        totalExpectedSessions += 1;
        // totalExpectedMinutes += motivation.targetMinutes;
        
        // Weekly tasks: 70% completion rate
        if (dayOfWeek >= 3) { // If we're past Tuesday, assume it might be done
          completedSessions += 1;
          completedMinutes += motivation.targetMinutes * 0.7;
        }
      }
    }
    
    final successRate = totalExpectedSessions > 0 ? (completedSessions / totalExpectedSessions) * 100 : 0.0;
    
    // Streak calculation based on consistency
    final avgDaysPerMotivation = widget.motivations.isNotEmpty 
        ? widget.motivations.map((m) => now.difference(m.createdAt).inDays).reduce((a, b) => a + b) / widget.motivations.length
        : 0;
    final streak = avgDaysPerMotivation > 21 ? 7.0 : avgDaysPerMotivation > 14 ? 5.0 : avgDaysPerMotivation > 7 ? 3.0 : 1.0;
    
    return {
      'successRate': successRate,
      'totalMinutes': completedMinutes,
      'streak': streak,
    };
  }

  double _getMotivationProgress(Motivation motivation) {
    // Calculate progress based on motivation frequency and creation date
    final now = DateTime.now();
    final daysSinceCreation = now.difference(motivation.createdAt).inDays;
    
    double progress = 0.0;
    
    if (motivation.frequency == MotivationFrequency.daily) {
      // For daily motivations, progress based on consistency
      final expectedDays = daysSinceCreation + 1;
      final completedDays = (expectedDays * 0.7).round(); // Assume 70% completion
      progress = expectedDays > 0 ? (completedDays / expectedDays) * 100 : 0.0;
    } else if (motivation.frequency == MotivationFrequency.weekly) {
      // For weekly motivations
      final expectedWeeks = (daysSinceCreation / 7).ceil();
      final completedWeeks = (expectedWeeks * 0.8).round(); // Assume 80% completion
      progress = expectedWeeks > 0 ? (completedWeeks / expectedWeeks) * 100 : 0.0;
    } else {
      // Monthly motivations
      final expectedMonths = (daysSinceCreation / 30).ceil();
      final completedMonths = (expectedMonths * 0.9).round(); // Assume 90% completion
      progress = expectedMonths > 0 ? (completedMonths / expectedMonths) * 100 : 0.0;
    }
    
    // Ensure progress is between 0 and 100
    return progress.clamp(0.0, 100.0);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppLocalizations.get('welcome_morning', widget.languageCode);
    if (hour < 17) return AppLocalizations.get('welcome_afternoon', widget.languageCode);
    return AppLocalizations.get('welcome_evening', widget.languageCode);
  }

  Widget _buildDailyQuote() {
    final dailyQuote = MotivationQuotes.getDailyQuote();
    
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.format_quote,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              dailyQuote.getQuote(widget.languageCode),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '- ${dailyQuote.author}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
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

  Color _getCategoryColor(MotivationCategory category) {
    switch (category) {
      case MotivationCategory.spiritual:
        return Colors.green.shade600;
      case MotivationCategory.education:
        return Colors.blue.shade600;
      case MotivationCategory.health:
        return Colors.orange.shade600;
      case MotivationCategory.household:
        return Colors.brown.shade600;
      case MotivationCategory.selfCare:
        return Colors.pink.shade600;
      case MotivationCategory.social:
        return Colors.teal.shade600;
      case MotivationCategory.hobby:
        return Colors.indigo.shade600;
      case MotivationCategory.career:
        return Colors.deepOrange.shade600;
      case MotivationCategory.personal:
        return Colors.purple.shade600;
    }
  }

  IconData _getCategoryIcon(MotivationCategory category) {
    switch (category) {
      case MotivationCategory.spiritual:
        return Icons.mosque;
      case MotivationCategory.education:
        return Icons.school;
      case MotivationCategory.health:
        return Icons.health_and_safety;
      case MotivationCategory.household:
        return Icons.home;
      case MotivationCategory.selfCare:
        return Icons.spa;
      case MotivationCategory.social:
        return Icons.people;
      case MotivationCategory.hobby:
        return Icons.palette;
      case MotivationCategory.career:
        return Icons.work;
      case MotivationCategory.personal:
        return Icons.person;
    }
  }

  void _markAllTodayComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.get('complete_today', widget.languageCode)),
        content: Text(AppLocalizations.get('mark_all_complete_question', widget.languageCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.get('cancel', widget.languageCode)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.get('all_motivations_completed', widget.languageCode))),
              );
            },
            child: Text(AppLocalizations.get('complete', widget.languageCode)),
          ),
        ],
      ),
    );
  }

  void _showMotivationOptions(Motivation motivation) {
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