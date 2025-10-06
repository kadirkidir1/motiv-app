import 'package:flutter/material.dart';

enum MotivationCategory {
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

enum MotivationFrequency {
  daily,
  weekly,
  monthly,
}

class Motivation {
  final String id;
  final String title;
  final String description;
  final MotivationCategory category;
  final MotivationFrequency frequency;
  final bool hasAlarm;
  final TimeOfDay? alarmTime;
  final DateTime createdAt;
  final bool isCompleted;
  final int targetMinutes;

  Motivation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.frequency,
    this.hasAlarm = false,
    this.alarmTime,
    required this.createdAt,
    this.isCompleted = false,
    this.targetMinutes = 0,
  });

  Motivation copyWith({
    String? id,
    String? title,
    String? description,
    MotivationCategory? category,
    MotivationFrequency? frequency,
    bool? hasAlarm,
    TimeOfDay? alarmTime,
    DateTime? createdAt,
    bool? isCompleted,
    int? targetMinutes,
  }) {
    return Motivation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      alarmTime: alarmTime ?? this.alarmTime,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      targetMinutes: targetMinutes ?? this.targetMinutes,
    );
  }
}

class MotivationProgress {
  final String motivationId;
  final DateTime date;
  final bool completed;
  final int minutesSpent;

  MotivationProgress({
    required this.motivationId,
    required this.date,
    required this.completed,
    this.minutesSpent = 0,
  });
}