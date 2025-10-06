import 'package:flutter/material.dart';
import '../models/daily_task.dart';
import '../services/language_service.dart';
import '../services/database_service.dart';

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
      setState(() {
        tasks = loadedTasks;
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
      appBar: AppBar(
        title: Text(AppLocalizations.get('daily_tasks', widget.languageCode)),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeTasks.isNotEmpty) ...[
            _buildSectionHeader(AppLocalizations.get('active_tasks', widget.languageCode), Colors.green),
            ...activeTasks.map((task) => _buildTaskCard(task)),
            const SizedBox(height: 16),
          ],
          if (expiredTasks.isNotEmpty) ...[
            _buildSectionHeader(AppLocalizations.get('expired_tasks', widget.languageCode), Colors.red),
            ...expiredTasks.map((task) => _buildTaskCard(task)),
            const SizedBox(height: 16),
          ],
          if (completedTasks.isNotEmpty) ...[
            _buildSectionHeader(AppLocalizations.get('completed_tasks', widget.languageCode), Colors.blue),
            ...completedTasks.map((task) => _buildTaskCard(task)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(DailyTask task) {
    Color cardColor;
    IconData statusIcon;
    Color statusColor;

    switch (task.status) {
      case TaskStatus.completed:
        cardColor = Colors.green.shade50;
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case TaskStatus.expired:
        cardColor = Colors.red.shade50;
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      default:
        cardColor = Colors.blue.shade50;
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
              '${AppLocalizations.get('expires', widget.languageCode)}: ${_formatDateTime(task.expiresAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: task.status == TaskStatus.pending
            ? PopupMenuButton(
                itemBuilder: (context) => [
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
              )
            : null,
      ),
    );
  }

  void _addNewTask() {
    showDialog(
      context: context,
      builder: (context) => _AddTaskDialog(
        languageCode: widget.languageCode,
        onTaskAdded: (task) async {
          await DatabaseService.insertDailyTask(task);
          setState(() {
            tasks.add(task);
          });
        },
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.get('add_daily_task', widget.languageCode)),
      content: Column(
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
          Row(
            children: [
              Text(AppLocalizations.get('expires_in', widget.languageCode)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedHours,
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
            ],
          ),
        ],
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

  void _saveTask() {
    if (_titleController.text.isEmpty) return;

    final task = DailyTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(hours: _selectedHours)),
    );

    widget.onTaskAdded(task);
    Navigator.pop(context);
  }
}