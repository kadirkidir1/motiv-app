class TaskCompletion {
  final String id;
  final String taskId;
  final DateTime completedAt;
  final int? completionTimeMinutes;
  final String? notes;

  TaskCompletion({
    required this.id,
    required this.taskId,
    required this.completedAt,
    this.completionTimeMinutes,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'task_id': taskId,
        'completed_at': completedAt.toIso8601String(),
        'completion_time_minutes': completionTimeMinutes,
        'notes': notes,
      };

  factory TaskCompletion.fromJson(Map<String, dynamic> json) {
    return TaskCompletion(
      id: json['id']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? '',
      completedAt: DateTime.parse(json['completed_at'].toString()),
      completionTimeMinutes: json['completion_time_minutes'] as int?,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toLocalDb() => {
        'id': id,
        'taskId': taskId,
        'completedAt': completedAt.toIso8601String(),
        'completionTimeMinutes': completionTimeMinutes,
        'notes': notes,
      };

  factory TaskCompletion.fromLocalDb(Map<String, dynamic> map) {
    return TaskCompletion(
      id: map['id']?.toString() ?? '',
      taskId: map['taskId']?.toString() ?? '',
      completedAt: DateTime.parse(map['completedAt'].toString()),
      completionTimeMinutes: map['completionTimeMinutes'] as int?,
      notes: map['notes']?.toString(),
    );
  }
}
