class DailyNote {
  final String id;
  final String routineId;
  final DateTime date;
  final String? note;  // Artık opsiyonel
  final int mood; // 1-5 arası mood skoru
  final List<String> tags;

  DailyNote({
    required this.id,
    required this.routineId,
    required this.date,
    this.note,  // Opsiyonel
    this.mood = 3,
    this.tags = const [],
  });

  DailyNote copyWith({
    String? id,
    String? routineId,
    DateTime? date,
    String? note,
    int? mood,
    List<String>? tags,
  }) {
    return DailyNote(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      date: date ?? this.date,
      note: note ?? this.note,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
    );
  }
}