import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/routine_completion.dart';
import '../models/task_completion.dart';
import 'database_service.dart';

class TrackingService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================
  // RUTIN TAMAMLANMA FONKSİYONLARI
  // ============================================

  /// Rutini bugün için tamamla
  static Future<void> completeRoutine({
    required String routineId,
    required DateTime date,
    int minutesSpent = 0,
    String? notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);

    final completion = RoutineCompletion(
      id: '${routineId}_${dateOnly.toIso8601String().split('T')[0]}',
      routineId: routineId,
      date: dateOnly,
      completedAt: now,
      minutesSpent: minutesSpent,
      notes: notes,
    );

    // Local'e kaydet
    final db = await DatabaseService.database;
    await db.insert(
      'routine_completions',
      completion.toLocalDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Cloud'a senkronize et
    try {
      final data = completion.toJson();
      data['user_id'] = user.id;
      await _supabase.from('routine_completions').upsert(data);
      developer.log('✅ Routine completion synced to cloud', name: 'TrackingService');
    } catch (e) {
      developer.log('❌ Cloud sync error: $e', name: 'TrackingService');
    }
  }

  /// Rutinin bugünkü tamamlanmasını geri al
  static Future<void> uncompleteRoutine(String routineId, DateTime date) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateStr = dateOnly.toIso8601String().split('T')[0];

    // Local'den sil
    final db = await DatabaseService.database;
    await db.delete(
      'routine_completions',
      where: 'routineId = ? AND date = ?',
      whereArgs: [routineId, dateStr],
    );

    // Cloud'dan sil
    try {
      await _supabase
          .from('routine_completions')
          .delete()
          .eq('routine_id', routineId)
          .eq('date', dateStr)
          .eq('user_id', user.id);
      developer.log('✅ Routine completion deleted from cloud', name: 'TrackingService');
    } catch (e) {
      developer.log('❌ Cloud delete error: $e', name: 'TrackingService');
    }
  }

  /// Bugün tamamlandı mı?
  static Future<bool> isCompletedToday(String routineId) async {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    final dateStr = dateOnly.toIso8601String().split('T')[0];

    final db = await DatabaseService.database;
    final result = await db.query(
      'routine_completions',
      where: 'routineId = ? AND date = ?',
      whereArgs: [routineId, dateStr],
    );

    return result.isNotEmpty;
  }

  /// Belirli bir tarihte tamamlandı mı?
  static Future<bool> isCompletedOnDate(String routineId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateStr = dateOnly.toIso8601String().split('T')[0];

    final db = await DatabaseService.database;
    final result = await db.query(
      'routine_completions',
      where: 'routineId = ? AND date = ?',
      whereArgs: [routineId, dateStr],
    );

    return result.isNotEmpty;
  }

  /// Rutinin tüm tamamlanma kayıtlarını getir
  static Future<List<RoutineCompletion>> getRoutineCompletions(
    String routineId, {
    int? days,
  }) async {
    final db = await DatabaseService.database;
    
    String whereClause = 'routineId = ?';
    List<dynamic> whereArgs = [routineId];
    
    if (days != null) {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final startDateStr = startDate.toIso8601String().split('T')[0];
      whereClause += ' AND date >= ?';
      whereArgs.add(startDateStr);
    }

    final result = await db.query(
      'routine_completions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return result.map((map) => RoutineCompletion.fromLocalDb(map)).toList();
  }

  /// Streak (seri) hesapla - DOĞRU ALGORİTMA
  static Future<int> calculateStreak(String routineId) async {
    final completions = await getRoutineCompletions(routineId, days: 365);
    
    if (completions.isEmpty) return 0;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final yesterday = todayOnly.subtract(const Duration(days: 1));

    // İlk tamamlanma tarihini kontrol et
    final firstDate = DateTime(
      completions.first.date.year,
      completions.first.date.month,
      completions.first.date.day,
    );

    // Bugün veya dün tamamlanmadıysa streak yok
    if (!firstDate.isAtSameMomentAs(todayOnly) && 
        !firstDate.isAtSameMomentAs(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime? lastDate;

    for (var completion in completions) {
      final date = DateTime(
        completion.date.year,
        completion.date.month,
        completion.date.day,
      );

      if (lastDate == null) {
        streak = 1;
        lastDate = date;
      } else {
        final diff = lastDate.difference(date).inDays;
        if (diff == 1) {
          streak++;
          lastDate = date;
        } else {
          break; // Streak kırıldı
        }
      }
    }

    return streak;
  }

  /// En uzun streak'i hesapla
  static Future<int> calculateLongestStreak(String routineId) async {
    final completions = await getRoutineCompletions(routineId, days: 365);
    
    if (completions.isEmpty) return 0;

    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    for (var completion in completions.reversed) {
      final date = DateTime(
        completion.date.year,
        completion.date.month,
        completion.date.day,
      );

      if (lastDate == null) {
        currentStreak = 1;
        lastDate = date;
      } else {
        final diff = date.difference(lastDate).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }
          currentStreak = 1;
        }
        lastDate = date;
      }
    }

    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    return longestStreak;
  }

  /// Başarı oranı hesapla (son X gün)
  static Future<double> calculateSuccessRate(String routineId, int days) async {
    final completions = await getRoutineCompletions(routineId, days: days);
    
    if (days == 0) return 0.0;
    
    return (completions.length / days * 100).clamp(0, 100);
  }

  /// Toplam tamamlanma sayısı
  static Future<int> getTotalCompletions(String routineId) async {
    final db = await DatabaseService.database;
    final result = await db.query(
      'routine_completions',
      where: 'routineId = ?',
      whereArgs: [routineId],
    );
    return result.length;
  }

  /// Ortalama harcanan dakika
  static Future<int> getAverageMinutesSpent(String routineId) async {
    final completions = await getRoutineCompletions(routineId);
    
    if (completions.isEmpty) return 0;
    
    final totalMinutes = completions.fold<int>(
      0,
      (sum, completion) => sum + completion.minutesSpent,
    );
    
    return (totalMinutes / completions.length).round();
  }

  // ============================================
  // TASK TAMAMLANMA FONKSİYONLARI
  // ============================================

  /// Task'ı tamamla
  static Future<void> completeTask(
    String taskId, {
    int? completionTimeMinutes,
    String? notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final now = DateTime.now();
    final completion = TaskCompletion(
      id: '${taskId}_${now.millisecondsSinceEpoch}',
      taskId: taskId,
      completedAt: now,
      completionTimeMinutes: completionTimeMinutes,
      notes: notes,
    );

    // Local'e kaydet
    final db = await DatabaseService.database;
    await db.insert(
      'task_completions',
      completion.toLocalDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Cloud'a senkronize et
    try {
      final data = completion.toJson();
      data['user_id'] = user.id;
      await _supabase.from('task_completions').insert(data);
      developer.log('✅ Task completion synced to cloud', name: 'TrackingService');
    } catch (e) {
      developer.log('❌ Cloud sync error: $e', name: 'TrackingService');
    }
  }

  /// Task'ın tamamlanma kayıtlarını getir
  static Future<List<TaskCompletion>> getTaskCompletions(String taskId) async {
    final db = await DatabaseService.database;
    final result = await db.query(
      'task_completions',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'completedAt DESC',
    );

    return result.map((map) => TaskCompletion.fromLocalDb(map)).toList();
  }

  // ============================================
  // SENKRONIZASYON FONKSİYONLARI
  // ============================================

  /// Cloud'dan tüm tamamlanma kayıtlarını senkronize et
  static Future<void> syncCompletionsFromCloud() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      developer.log('❌ No user logged in', name: 'TrackingService');
      return;
    }

    try {
      final db = await DatabaseService.database;

      // Routine completions'ları senkronize et
      developer.log('📥 Syncing routine completions...', name: 'TrackingService');
      final routineCompletions = await _supabase
          .from('routine_completions')
          .select()
          .eq('user_id', user.id);

      for (var data in routineCompletions) {
        final completion = RoutineCompletion.fromJson(data);
        await db.insert(
          'routine_completions',
          completion.toLocalDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      developer.log('✅ Synced ${routineCompletions.length} routine completions', name: 'TrackingService');

      // Task completions'ları senkronize et
      developer.log('📥 Syncing task completions...', name: 'TrackingService');
      final taskCompletions = await _supabase
          .from('task_completions')
          .select()
          .eq('user_id', user.id);

      for (var data in taskCompletions) {
        final completion = TaskCompletion.fromJson(data);
        await db.insert(
          'task_completions',
          completion.toLocalDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      developer.log('✅ Synced ${taskCompletions.length} task completions', name: 'TrackingService');

    } catch (e, stackTrace) {
      developer.log('❌ Sync error: $e', name: 'TrackingService');
      developer.log('Stack trace: $stackTrace', name: 'TrackingService');
      rethrow;
    }
  }
}
