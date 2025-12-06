class RoutineCompletion {
  final String id;
  final String routineId;
  final DateTime date;
  final DateTime completedAt;
  final int minutesSpent;
  final String? notes;

  RoutineCompletion({
    required this.id,
    required this.routineId,
    required this.date,
    required this.completedAt,
    this.minutesSpent = 0,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'routine_id': routineId,
        'date': date.toIso8601String().split('T')[0],
        'completed_at': completedAt.toIso8601String(),
        'minutes_spent': minutesSpent,
        'notes': notes,
      };

  factory RoutineCompletion.fromJson(Map<String, dynamic> json) {
    return RoutineCompletion(
      id: json['id']?.toString() ?? '',
      routineId: json['routine_id']?.toString() ?? '',
      date: DateTime.parse(json['date'].toString()),
      completedAt: DateTime.parse(json['completed_at'].toString()),
      minutesSpent: (json['minutes_spent'] ?? 0) as int,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toLocalDb() => {
        'id': id,
        'routineId': routineId,
        'date': date.toIso8601String().split('T')[0],
        'completedAt': completedAt.toIso8601String(),
        'minutesSpent': minutesSpent,
        'notes': notes,
      };

  factory RoutineCompletion.fromLocalDb(Map<String, dynamic> map) {
    return RoutineCompletion(
      id: map['id']?.toString() ?? '',
      routineId: map['routineId']?.toString() ?? '',
      date: DateTime.parse(map['date'].toString()),
      completedAt: DateTime.parse(map['completedAt'].toString()),
      minutesSpent: (map['minutesSpent'] ?? 0) as int,
      notes: map['notes']?.toString(),
    );
  }
}
