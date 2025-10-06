enum TaskStatus {
  pending,
  completed,
  expired,
}

class DailyTask {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime expiresAt;
  final TaskStatus status;
  final bool addToCalendar;

  DailyTask({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.expiresAt,
    this.status = TaskStatus.pending,
    this.addToCalendar = false,
  });

  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? expiresAt,
    TaskStatus? status,
    bool? addToCalendar,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      addToCalendar: addToCalendar ?? this.addToCalendar,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt) && status == TaskStatus.pending;
  bool get isActive => status == TaskStatus.pending && !isExpired;
}