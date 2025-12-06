import 'package:flutter/material.dart';

enum RoutineCategory {
  spiritual, // Manevi (Namaz, Kuran)
  education, // Eğitim (İngilizce, Kitap)
  health, // Sağlık (Diş fırçalama, Spor)
  personal, // Kişisel gelişim
  household, // Ev İşleri
  selfCare, // Kişisel Bakım
  social, // Sosyal
  hobby, // Hobi
  career, // İş/Kariyer
}

enum RoutineFrequency {
  daily,
  weekly,
  monthly,
}

class Routine {
  final String id;
  final String title;
  final String description;
  final RoutineCategory category;
  final RoutineFrequency frequency;
  final bool hasAlarm;
  final TimeOfDay? alarmTime;
  final DateTime createdAt;
  final bool isCompleted;  // DEPRECATED: Kullanılmıyor, geriye dönük uyumluluk için
  final bool isArchived;  // Rutin arşivlendi mi?
  final int targetMinutes;
  final bool isTimeBased;
  final String? customNotificationMessage;

  Routine({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.frequency,
    this.hasAlarm = false,
    this.alarmTime,
    required this.createdAt,
    @Deprecated('Use isArchived instead') this.isCompleted = false,
    this.isArchived = false,
    this.targetMinutes = 0,
    this.isTimeBased = true,
    this.customNotificationMessage,
  });

  Routine copyWith({
    String? id,
    String? title,
    String? description,
    RoutineCategory? category,
    RoutineFrequency? frequency,
    bool? hasAlarm,
    TimeOfDay? alarmTime,
    DateTime? createdAt,
    bool? isCompleted,
    bool? isArchived,
    int? targetMinutes,
    bool? isTimeBased,
    String? customNotificationMessage,
  }) {
    return Routine(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      alarmTime: alarmTime ?? this.alarmTime,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      isArchived: isArchived ?? this.isArchived,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      isTimeBased: isTimeBased ?? this.isTimeBased,
      customNotificationMessage: customNotificationMessage ?? this.customNotificationMessage,
    );
  }
}

class RoutineProgress {
  final String routineId;
  final DateTime date;
  final bool completed;
  final int minutesSpent;

  RoutineProgress({
    required this.routineId,
    required this.date,
    required this.completed,
    this.minutesSpent = 0,
  });
}