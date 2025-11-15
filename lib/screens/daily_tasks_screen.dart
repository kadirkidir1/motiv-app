import 'package:flutter/material.dart';
import '../models/daily_task.dart';
import '../services/language_service.dart';
import '../services/database_service.dart';
import '../services/subscription_service.dart';
import '../services/notification_service.dart';
import 'premium_screen.dart';

class DailyTasksScreen extends StatefulWidget {
  final String languageCode;

  const DailyTasksScreen({
    super.key,
    required this.languageCode,
  });

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  List<DailyTask> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final loadedTasks = await DatabaseService.getDailyTasks();
      
      // Süre kontrolü yap - sadece pending task'lar için status güncelle
      for (var task in loadedTasks) {
        if (task.status == TaskStatus.pending && task.isExpired) {
          final expiredTask = task.copyWith(status: TaskStatus.expired);
          await DatabaseService.updateDailyTask(expiredTask);
        }
      }
      
      // Güncellenmiş task'ları tekrar yükle
      final updatedTasks = await DatabaseService.getDailyTasks();
      setState(() {
        tasks = updatedTasks;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTasks = tasks.where((task) => task.isActive).toList();
    final expiredTasks = tasks.where((task) => task.isExpired).toList();
    final completedTasks = tasks.where((task) => task.status == TaskStatus.completed).toList();

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? _buildEmptyState()
              : _buildTasksList(activeTasks, expiredTasks, completedTasks),
      floatingActionButton: FloatingActionButton(
        heroTag: "add_task",
        onPressed: _addNewTask,
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.get('no_daily_tasks', widget.languageCode),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.get('add_first_task', widget.languageCode),
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

  Widget _buildTasksList(List<DailyTask> activeTasks, List<DailyTask> expiredTasks, List<DailyTask> completedTasks) {
    final allTasks = [...activeTasks, ...expiredTasks, ...completedTasks];
    final grouped = _groupTasksByTime(allTasks);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (grouped['today']!.isNotEmpty)
            _buildExpandableSection(
              widget.languageCode == 'tr' ? 'Bugünün Görevleri' : 'Today\'s Tasks',
              grouped['today']!,
              Colors.blue,
              true,
            ),
          if (grouped['week']!.isNotEmpty)
            _buildExpandableSection(
              widget.languageCode == 'tr' ? 'Bu Hafta' : 'This Week',
              grouped['week']!,
              Colors.orange,
              false,
            ),
          if (grouped['month']!.isNotEmpty)
            _buildExpandableSection(
              widget.languageCode == 'tr' ? 'Bu Ay' : 'This Month',
              grouped['month']!,
              Colors.purple,
              false,
            ),
          if (grouped['year']!.isNotEmpty)
            _buildExpandableSection(
              widget.languageCode == 'tr' ? 'Son 1 Yıl' : 'Last Year',
              grouped['year']!,
              Colors.grey,
              false,
            ),
        ],
      ),
    );
  }

  Map<String, List<DailyTask>> _groupTasksByTime(List<DailyTask> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final yearStart = DateTime(now.year, 1, 1);

    final Map<String, List<DailyTask>> grouped = {
      'today': [],
      'week': [],
      'month': [],
      'year': [],
    };

    for (final task in tasks) {
      final taskDate = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
      
      if (taskDate.isAtSameMomentAs(today)) {
        grouped['today']!.add(task);
      } else if (taskDate.isAfter(weekStart) && taskDate.isBefore(today)) {
        grouped['week']!.add(task);
      } else if (taskDate.isAfter(monthStart) && taskDate.isBefore(weekStart)) {
        grouped['month']!.add(task);
      } else if (taskDate.isAfter(yearStart)) {
        grouped['year']!.add(task);
      }
    }

    return grouped;
  }

  Widget _buildExpandableSection(String title, List<DailyTask> tasks, Color color, bool initiallyExpanded) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            '${tasks.length}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        children: tasks.map((task) => _buildTaskCard(task)).toList(),
      ),
    );
  }



  Widget _buildTaskCard(DailyTask task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor;
    IconData statusIcon;
    Color statusColor;

    switch (task.status) {
      case TaskStatus.completed:
        cardColor = isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50;
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case TaskStatus.expired:
        cardColor = isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50;
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      default:
        cardColor = isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50;
        statusIcon = Icons.schedule;
        statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null) Text(task.description!),
            const SizedBox(height: 4),
            Text(
              _getTimeRemainingText(task),
              style: TextStyle(
                fontSize: 12,
                color: _isExpired(task) ? Colors.red.shade600 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
            itemBuilder: (context) => [
              if (task.status == TaskStatus.pending)
                PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      const Icon(Icons.check, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.get('mark_complete', widget.languageCode)),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.get('delete', widget.languageCode)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'complete') {
                _completeTask(task);
              } else if (value == 'delete') {
                _deleteTask(task);
              }
            },
          ),
      ),
    );
  }

  void _addNewTask() async {
    final canAdd = await SubscriptionService.canAddTask();
    if (!mounted) return;
    
    if (!canAdd) {
      _showPremiumRequired();
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => _AddTaskDialog(
        languageCode: widget.languageCode,
        onTaskAdded: (task) async {
          await DatabaseService.insertDailyTask(task);
          
          // Süre dolduğunda bildirim
          await NotificationService.scheduleTaskExpiration(task.id, task.title, task.expiresAt);
          
          // Alarm kurulduysa, belirlenen saatte bildirim
          if (task.hasAlarm && task.alarmTime != null) {
            await NotificationService.scheduleTaskReminder(task.id, task.title, task.alarmTime!);
          }
          
          setState(() {
            tasks.add(task);
          });
        },
      ),
    );
  }

  void _showPremiumRequired() {
    final isTurkish = widget.languageCode == 'tr';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            Text(isTurkish ? 'Premium Gerekli' : 'Premium Required'),
          ],
        ),
        content: Text(
          isTurkish
              ? 'Ücretsiz hesapta en fazla 2 görev ekleyebilirsiniz. Sınırsız görev için Premium\'a geçin!'
              : 'Free accounts can add up to 2 tasks. Upgrade to Premium for unlimited tasks!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTurkish ? 'İptal' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
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
    );
  }

  void _completeTask(DailyTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.get('task_completed', widget.languageCode)),
        content: Text(AppLocalizations.get('add_to_calendar_question', widget.languageCode)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateTaskStatus(task, TaskStatus.completed, false);
            },
            child: Text(AppLocalizations.get('no', widget.languageCode)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateTaskStatus(task, TaskStatus.completed, true);
            },
            child: Text(AppLocalizations.get('yes', widget.languageCode)),
          ),
        ],
      ),
    );
  }

  void _updateTaskStatus(DailyTask task, TaskStatus status, bool addToCalendar) async {
    final updatedTask = task.copyWith(status: status, addToCalendar: addToCalendar);
    await DatabaseService.updateDailyTask(updatedTask);
    await NotificationService.cancelTaskNotification(task.id);
    
    setState(() {
      final index = tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        tasks[index] = updatedTask;
      }
    });

    if (addToCalendar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.get('added_to_calendar', widget.languageCode))),
      );
    }

    // 24 saat sonra tamamlanan taskları otomatik sil
    if (status == TaskStatus.completed) {
      Future.delayed(const Duration(hours: 24), () async {
        if (mounted) {
          await DatabaseService.deleteDailyTask(task.id);
          setState(() {
            tasks.removeWhere((t) => t.id == task.id);
          });
        }
      });
    }
  }

  void _deleteTask(DailyTask task) async {
    await DatabaseService.deleteDailyTask(task.id);
    await NotificationService.cancelTaskNotification(task.id);
    setState(() {
      tasks.removeWhere((t) => t.id == task.id);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.get('task_deleted', widget.languageCode))),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${AppLocalizations.get('days', widget.languageCode)}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${AppLocalizations.get('hours', widget.languageCode)}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${AppLocalizations.get('minutes', widget.languageCode)}';
    } else {
      return AppLocalizations.get('expired', widget.languageCode);
    }
  }

  bool _isExpired(DailyTask task) {
    return task.expiresAt.isBefore(DateTime.now());
  }

  String _getTimeRemainingText(DailyTask task) {
    if (_isExpired(task)) {
      return widget.languageCode == 'tr' ? 'Süresi bitti' : 'Expired';
    }
    final timeLeft = _formatDateTime(task.expiresAt);
    return widget.languageCode == 'tr' 
        ? 'Sürenin bitmesine $timeLeft kaldı'
        : '$timeLeft remaining';
  }
}

class _AddTaskDialog extends StatefulWidget {
  final String languageCode;
  final Function(DailyTask) onTaskAdded;

  const _AddTaskDialog({
    required this.languageCode,
    required this.onTaskAdded,
  });

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedHours = 24;
  TaskDeadlineType _deadlineType = TaskDeadlineType.hours;
  DateTime? _selectedDateTime;
  bool _hasAlarm = false;
  DateTime? _alarmTime;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.get('add_daily_task', widget.languageCode)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.get('task_title', widget.languageCode),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.get('description', widget.languageCode),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskDeadlineType>(
              initialValue: _deadlineType,
              decoration: InputDecoration(
                labelText: widget.languageCode == 'tr' ? 'Bitiş Zamanı' : 'Deadline Type',
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: TaskDeadlineType.hours,
                  child: Text(widget.languageCode == 'tr' ? 'Kaç saat içinde' : 'Within hours'),
                ),
                DropdownMenuItem(
                  value: TaskDeadlineType.endOfDay,
                  child: Text(widget.languageCode == 'tr' ? 'Gün sonuna kadar' : 'End of day'),
                ),
                DropdownMenuItem(
                  value: TaskDeadlineType.specificDateTime,
                  child: Text(widget.languageCode == 'tr' ? 'Belirli tarih/saat' : 'Specific date/time'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _deadlineType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_deadlineType == TaskDeadlineType.hours)
              DropdownButton<int>(
                value: _selectedHours,
                isExpanded: true,
                items: [1, 2, 6, 12, 24, 48].map((hours) {
                  return DropdownMenuItem(
                    value: hours,
                    child: Text('$hours ${AppLocalizations.get('hours', widget.languageCode)}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedHours = value!;
                  });
                },
              ),
            if (_deadlineType == TaskDeadlineType.specificDateTime)
              ListTile(
                title: Text(
                  _selectedDateTime != null
                      ? '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} ${_selectedDateTime!.hour}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}'
                      : (widget.languageCode == 'tr' ? 'Tarih ve saat seç' : 'Select date and time'),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDateTime,
              ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(widget.languageCode == 'tr' ? 'Alarm Kur' : 'Set Alarm'),
              value: _hasAlarm,
              onChanged: (value) {
                setState(() {
                  _hasAlarm = value;
                });
              },
            ),
            if (_hasAlarm)
              ListTile(
                title: Text(
                  _alarmTime != null
                      ? '${_alarmTime!.hour}:${_alarmTime!.minute.toString().padLeft(2, '0')}'
                      : (widget.languageCode == 'tr' ? 'Alarm saati seç' : 'Select alarm time'),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: _selectAlarmTime,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.get('cancel', widget.languageCode)),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          child: Text(AppLocalizations.get('save', widget.languageCode)),
        ),
      ],
    );
  }

  void _saveTask() async {
    if (_titleController.text.isEmpty) return;

    DateTime expiresAt;
    switch (_deadlineType) {
      case TaskDeadlineType.hours:
        expiresAt = DateTime.now().add(Duration(hours: _selectedHours));
        break;
      case TaskDeadlineType.endOfDay:
        final now = DateTime.now();
        expiresAt = DateTime(now.year, now.month, now.day, 23, 59);
        break;
      case TaskDeadlineType.specificDateTime:
        if (_selectedDateTime == null) return;
        expiresAt = _selectedDateTime!;
        break;
    }

    final task = DailyTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      hasAlarm: _hasAlarm,
      alarmTime: _alarmTime,
      deadlineType: _deadlineType,
    );

    widget.onTaskAdded(task);
    Navigator.pop(context);
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _selectAlarmTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final now = DateTime.now();
    setState(() {
      _alarmTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    });
  }
}