class DailyNote {
  final String id;
  final String motivationId;
  final DateTime date;
  final String note;
  final int mood; // 1-5 arası mood skoru
  final List<String> tags;

  DailyNote({
    required this.id,
    required this.motivationId,
    required this.date,
    required this.note,
    this.mood = 3,
    this.tags = const [],
  });

  DailyNote copyWith({
    String? id,
    String? motivationId,
    DateTime? date,
    String? note,
    int? mood,
    List<String>? tags,
  }) {
    return DailyNote(
      id: id ?? this.id,
      motivationId: motivationId ?? this.motivationId,
      date: date ?? this.date,
      note: note ?? this.note,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
    );
  }
}