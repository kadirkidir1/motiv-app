enum TaskStatus {
  pending,
  completed,
  expired,
}

enum TaskDeadlineType {
  hours, // Kaç saat içinde
  specificDateTime, // Belirli tarih ve saat
  endOfDay, // Gün sonuna kadar
}

class DailyTask {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime expiresAt;
  final TaskStatus status;
  final bool addToCalendar;
  final bool hasAlarm;
  final DateTime? alarmTime;
  final TaskDeadlineType deadlineType;
  final String? customNotificationMessage;

  DailyTask({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.expiresAt,
    this.status = TaskStatus.pending,
    this.addToCalendar = false,
    this.hasAlarm = false,
    this.alarmTime,
    this.deadlineType = TaskDeadlineType.hours,
    this.customNotificationMessage,
  });

  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? expiresAt,
    TaskStatus? status,
    bool? addToCalendar,
    bool? hasAlarm,
    DateTime? alarmTime,
    TaskDeadlineType? deadlineType,
    String? customNotificationMessage,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      addToCalendar: addToCalendar ?? this.addToCalendar,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      alarmTime: alarmTime ?? this.alarmTime,
      deadlineType: deadlineType ?? this.deadlineType,
      customNotificationMessage: customNotificationMessage ?? this.customNotificationMessage,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt) && status == TaskStatus.pending;
  bool get isActive => status == TaskStatus.pending && !isExpired;
}