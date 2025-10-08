import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/motivation.dart';
import '../models/daily_task.dart';
import '../models/daily_note.dart';

class DatabaseService {
  static Database? _database;
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'motiv_app.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add daily_notes table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_notes(
          id TEXT PRIMARY KEY,
          motivationId TEXT NOT NULL,
          date TEXT NOT NULL,
          note TEXT NOT NULL,
          mood INTEGER NOT NULL,
          tags TEXT,
          completed INTEGER NOT NULL,
          minutesSpent INTEGER NOT NULL,
          syncedToCloud INTEGER DEFAULT 0
        )
      ''');
    }
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE motivations(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        frequency TEXT NOT NULL,
        hasAlarm INTEGER NOT NULL,
        alarmTime TEXT,
        createdAt TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        targetMinutes INTEGER NOT NULL,
        syncedToCloud INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        createdAt TEXT NOT NULL,
        expiresAt TEXT NOT NULL,
        status TEXT NOT NULL,
        addToCalendar INTEGER NOT NULL,
        syncedToCloud INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_notes(
        id TEXT PRIMARY KEY,
        motivationId TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT NOT NULL,
        mood INTEGER NOT NULL,
        tags TEXT,
        completed INTEGER NOT NULL,
        minutesSpent INTEGER NOT NULL,
        syncedToCloud INTEGER DEFAULT 0
      )
    ''');
  }

  // Motivations CRUD
  static Future<void> insertMotivation(Motivation motivation) async {
    final db = await database;
    await db.insert('motivations', _motivationToMap(motivation));
    _syncMotivationToCloud(motivation);
  }

  static Future<List<Motivation>> getMotivations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('motivations');
    return List.generate(maps.length, (i) => _motivationFromMap(maps[i]));
  }

  static Future<void> updateMotivation(Motivation motivation) async {
    final db = await database;
    await db.update(
      'motivations',
      _motivationToMap(motivation),
      where: 'id = ?',
      whereArgs: [motivation.id],
    );
    _syncMotivationToCloud(motivation);
  }

  static Future<void> deleteMotivation(String id) async {
    final db = await database;
    // Önce motivasyona ait notları sil
    await db.delete('daily_notes', where: 'motivationId = ?', whereArgs: [id]);
    // Sonra motivasyonu sil
    await db.delete('motivations', where: 'id = ?', whereArgs: [id]);
    _deleteMotivationFromCloud(id);
    // Cloud'dan notları da sil
    _deleteMotivationNotesFromCloud(id);
  }

  static Future<void> clearAllMotivations() async {
    final db = await database;
    await db.delete('motivations');
    
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase
            .from('motivations')
            .delete()
            .eq('user_id', user.id);
      } catch (e) {
        developer.log('Cloud clear error: $e', name: 'DatabaseService');
      }
    }
  }

  static Future<void> translateExistingMotivations(String languageCode) async {
    final motivations = await getMotivations();
    
    for (final motivation in motivations) {
      String translatedTitle = motivation.title;
      String translatedDescription = motivation.description;
      
      // Check if this is a predefined motivation that needs translation
      if (_isPredefinedMotivation(motivation.title)) {
        final translations = _getPredefinedTranslations(motivation.title, languageCode);
        if (translations != null) {
          translatedTitle = translations['title'] ?? motivation.title;
          translatedDescription = translations['description'] ?? motivation.description;
          
          final updatedMotivation = motivation.copyWith(
            title: translatedTitle,
            description: translatedDescription,
          );
          
          await updateMotivation(updatedMotivation);
        }
      }
    }
  }

  static bool _isPredefinedMotivation(String title) {
    final predefinedTitles = [
      'Kuran Okuma', 'Quran Reading',
      '5 Vakit Namaz', '5 Daily Prayers',
      'İstiğfar Çekme', 'Istighfar',
      'Spor Yapma', 'Exercise',
      'İngilizce Çalışma', 'English Study',
      'Kitap Okuma', 'Book Reading',
      'Diş Fırçalama', 'Brush Teeth',
    ];
    return predefinedTitles.any((predefined) => title.contains(predefined));
  }

  static Map<String, String>? _getPredefinedTranslations(String title, String languageCode) {
    final translations = {
      'Kuran Okuma': {
        'en': {
          'title': 'Quran Reading',
          'description': 'Read Quran daily',
        },
        'tr': {
          'title': 'Kuran Okuma',
          'description': 'Her gün Kuran-ı Kerim okumak',
        },
      },
      'Quran Reading': {
        'en': {
          'title': 'Quran Reading',
          'description': 'Read Quran daily',
        },
        'tr': {
          'title': 'Kuran Okuma',
          'description': 'Her gün Kuran-ı Kerim okumak',
        },
      },
    };
    
    for (final key in translations.keys) {
      if (title.contains(key)) {
        return translations[key]?[languageCode];
      }
    }
    return null;
  }

  // Daily Tasks CRUD
  static Future<void> insertDailyTask(DailyTask task) async {
    final db = await database;
    await db.insert('daily_tasks', _taskToMap(task, forCloud: false));
    _syncTaskToCloud(task);
  }

  static Future<List<DailyTask>> getDailyTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('daily_tasks');
    return List.generate(maps.length, (i) => _taskFromMap(maps[i]));
  }

  static Future<void> updateDailyTask(DailyTask task) async {
    final db = await database;
    await db.update(
      'daily_tasks',
      _taskToMap(task, forCloud: false),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    _syncTaskToCloud(task);
  }

  static Future<void> deleteDailyTask(String id) async {
    final db = await database;
    await db.delete('daily_tasks', where: 'id = ?', whereArgs: [id]);
    _deleteTaskFromCloud(id);
  }

  // Daily Notes CRUD
  static Future<void> insertDailyNote(DailyNote note, bool completed, int minutesSpent) async {
    final db = await database;
    await db.insert('daily_notes', _noteToMap(note, completed, minutesSpent));
    _syncNoteToCloud(note, completed, minutesSpent);
  }

  static Future<List<DailyNote>> getDailyNotes(String motivationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_notes',
      where: 'motivationId = ?',
      whereArgs: [motivationId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => _noteFromMap(maps[i]));
  }

  static Future<void> updateDailyNote(DailyNote note, bool completed, int minutesSpent) async {
    final db = await database;
    await db.update(
      'daily_notes',
      _noteToMap(note, completed, minutesSpent),
      where: 'id = ?',
      whereArgs: [note.id],
    );
    _syncNoteToCloud(note, completed, minutesSpent);
  }

  static Future<void> deleteDailyNote(String id) async {
    final db = await database;
    await db.delete('daily_notes', where: 'id = ?', whereArgs: [id]);
    _deleteNoteFromCloud(id);
  }

  // Supabase Sync Methods
  static Future<void> _syncMotivationToCloud(Motivation motivation) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      developer.log('❌ No user logged in, skipping cloud sync', name: 'DatabaseService');
      return;
    }

    try {
      final motivationData = _motivationToMap(motivation, forCloud: true);
      motivationData['user_id'] = user.id;
      motivationData.remove('syncedToCloud');
      
      developer.log('📤 Syncing motivation: ${motivation.title} (ID: ${motivation.id})', name: 'DatabaseService');
      developer.log('📦 Data: $motivationData', name: 'DatabaseService');
      
      final response = await _supabase
          .from('motivations')
          .upsert(motivationData)
          .select();
      
      developer.log('✅ Motivation synced successfully: $response', name: 'DatabaseService');
    } catch (e, stackTrace) {
      developer.log('❌ Motivation cloud sync error: $e', name: 'DatabaseService');
      developer.log('Stack trace: $stackTrace', name: 'DatabaseService');
    }
  }

  static Future<void> _syncTaskToCloud(DailyTask task) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      developer.log('❌ No user logged in, skipping cloud sync', name: 'DatabaseService');
      return;
    }

    try {
      final taskData = _taskToMap(task, forCloud: true);
      taskData['user_id'] = user.id;
      
      developer.log('📤 Syncing task: ${task.title} (ID: ${task.id})', name: 'DatabaseService');
      developer.log('📦 Data: $taskData', name: 'DatabaseService');
      
      final response = await _supabase
          .from('daily_tasks')
          .upsert(taskData)
          .select();
      
      developer.log('✅ Task synced successfully: $response', name: 'DatabaseService');
    } catch (e, stackTrace) {
      developer.log('❌ Task cloud sync error: $e', name: 'DatabaseService');
      developer.log('Stack trace: $stackTrace', name: 'DatabaseService');
    }
  }

  static Future<void> _deleteMotivationFromCloud(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('motivations')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (e) {
      developer.log('Cloud delete error: $e', name: 'DatabaseService');
    }
  }

  static Future<void> _deleteTaskFromCloud(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('daily_tasks')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (e) {
      developer.log('Cloud delete error: $e', name: 'DatabaseService');
    }
  }

  static Future<void> _syncNoteToCloud(DailyNote note, bool completed, int minutesSpent) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      developer.log('❌ No user logged in, skipping cloud sync', name: 'DatabaseService');
      return;
    }

    try {
      final noteData = _noteToMap(note, completed, minutesSpent, forCloud: true);
      noteData['user_id'] = user.id;
      noteData.remove('syncedToCloud');
      
      developer.log('📤 Syncing note: ${note.id} for motivation: ${note.motivationId}', name: 'DatabaseService');
      developer.log('📦 Data: $noteData', name: 'DatabaseService');
      
      final response = await _supabase
          .from('daily_notes')
          .upsert(noteData)
          .select();
      
      developer.log('✅ Note synced successfully: $response', name: 'DatabaseService');
    } catch (e, stackTrace) {
      developer.log('❌ Note cloud sync error: $e', name: 'DatabaseService');
      developer.log('Stack trace: $stackTrace', name: 'DatabaseService');
    }
  }

  static Future<void> _deleteNoteFromCloud(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('daily_notes')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (e) {
      developer.log('Cloud delete error: $e', name: 'DatabaseService');
    }
  }

  static Future<void> _deleteMotivationNotesFromCloud(String motivationId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('daily_notes')
          .delete()
          .eq('motivation_id', motivationId)
          .eq('user_id', user.id);
    } catch (e) {
      developer.log('Cloud delete notes error: $e', name: 'DatabaseService');
    }
  }

  // Sync from Cloud to Local
  static Future<void> syncFromCloud() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      developer.log('❌ No user logged in, skipping sync', name: 'DatabaseService');
      return;
    }

    developer.log('🔄 Starting sync from cloud for user: ${user.id}', name: 'DatabaseService');

    try {
      final db = await database;
      
      // Local verileri temizle (sadece cloud'dan gelecek)
      await db.delete('motivations');
      await db.delete('daily_tasks');
      await db.delete('daily_notes');
      
      // Sync motivations
      developer.log('📥 Fetching motivations from cloud...', name: 'DatabaseService');
      final motivationsResponse = await _supabase
          .from('motivations')
          .select()
          .eq('user_id', user.id);

      developer.log('📊 Found ${motivationsResponse.length} motivations in cloud', name: 'DatabaseService');
      
      for (var data in motivationsResponse) {
          developer.log('📦 Motivation data from cloud: $data', name: 'DatabaseService');
          final motivation = _motivationFromMap(data);
          await db.insert(
            'motivations',
            _motivationToMap(motivation),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          developer.log('✅ Synced motivation: ${motivation.title}', name: 'DatabaseService');
        }

      // Sync tasks
      developer.log('📥 Fetching tasks from cloud...', name: 'DatabaseService');
      final tasksResponse = await _supabase
          .from('daily_tasks')
          .select()
          .eq('user_id', user.id);

      developer.log('📊 Found ${tasksResponse.length} tasks in cloud', name: 'DatabaseService');
      
      for (var data in tasksResponse) {
          developer.log('📦 Task data from cloud: $data', name: 'DatabaseService');
          final task = _taskFromMap(data);
          await db.insert(
            'daily_tasks',
            _taskToMap(task, forCloud: false),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          developer.log('✅ Synced task: ${task.title}', name: 'DatabaseService');
        }

      // Sync notes
      developer.log('📥 Fetching notes from cloud...', name: 'DatabaseService');
      final notesResponse = await _supabase
          .from('daily_notes')
          .select()
          .eq('user_id', user.id);

      developer.log('📊 Found ${notesResponse.length} notes in cloud', name: 'DatabaseService');
      
      for (var data in notesResponse) {
          developer.log('📦 Note data from cloud: $data', name: 'DatabaseService');
          final note = _noteFromMap(data);
          final completed = (data['completed'] == 1 || data['completed'] == true);
          final minutesSpent = (data['minutesSpent'] ?? data['minutes_spent'] ?? 0) as int;
          await db.insert(
            'daily_notes',
            _noteToMap(note, completed, minutesSpent),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          developer.log('✅ Synced note: ${note.id}', name: 'DatabaseService');
        }
      
      developer.log('🎉 Sync from cloud completed successfully', name: 'DatabaseService');
    } catch (e, stackTrace) {
      developer.log('❌ Sync from cloud error: $e', name: 'DatabaseService');
      developer.log('Stack trace: $stackTrace', name: 'DatabaseService');
      rethrow;
    }
  }

  // Helper methods
  static Map<String, dynamic> _motivationToMap(Motivation motivation, {bool forCloud = false}) {
    if (forCloud) {
      // Supabase için snake_case
      return {
        'id': motivation.id,
        'title': motivation.title,
        'description': motivation.description,
        'category': motivation.category.toString(),
        'frequency': motivation.frequency.toString(),
        'has_alarm': motivation.hasAlarm ? 1 : 0,
        'created_at': motivation.createdAt.toIso8601String(),
        'is_completed': motivation.isCompleted ? 1 : 0,
        'target_minutes': motivation.targetMinutes,
      };
    }
    
    // Local database için camelCase
    return {
      'id': motivation.id,
      'title': motivation.title,
      'description': motivation.description,
      'category': motivation.category.toString(),
      'frequency': motivation.frequency.toString(),
      'hasAlarm': motivation.hasAlarm ? 1 : 0,
      'alarmTime': motivation.alarmTime?.toString(),
      'createdAt': motivation.createdAt.toIso8601String(),
      'isCompleted': motivation.isCompleted ? 1 : 0,
      'targetMinutes': motivation.targetMinutes,
    };
  }

  static Motivation _motivationFromMap(Map<String, dynamic> map) {
    // Supabase'den gelen data snake_case olabilir
    final id = map['id']?.toString() ?? '';
    final title = map['title']?.toString() ?? '';
    final description = map['description']?.toString() ?? '';
    final categoryStr = map['category']?.toString() ?? 'MotivationCategory.personal';
    final frequencyStr = map['frequency']?.toString() ?? 'MotivationFrequency.daily';
    final hasAlarm = map['hasAlarm'] == 1 || map['has_alarm'] == true || map['has_alarm'] == 1;
    final alarmTimeStr = map['alarmTime'] ?? map['alarm_time'];
    final createdAtStr = map['createdAt'] ?? map['created_at'];
    final isCompleted = map['isCompleted'] == 1 || map['is_completed'] == true || map['is_completed'] == 1;
    final targetMinutes = (map['targetMinutes'] ?? map['target_minutes'] ?? 0) as int;
    
    return Motivation(
      id: id,
      title: title,
      description: description,
      category: MotivationCategory.values.firstWhere(
        (e) => e.toString() == categoryStr,
        orElse: () => MotivationCategory.personal,
      ),
      frequency: MotivationFrequency.values.firstWhere(
        (e) => e.toString() == frequencyStr,
        orElse: () => MotivationFrequency.daily,
      ),
      hasAlarm: hasAlarm,
      alarmTime: alarmTimeStr != null ? _parseTimeOfDay(alarmTimeStr.toString()) : null,
      createdAt: DateTime.parse(createdAtStr.toString()),
      isCompleted: isCompleted,
      targetMinutes: targetMinutes,
    );
  }

  static Map<String, dynamic> _taskToMap(DailyTask task, {bool forCloud = false}) {
    if (forCloud) {
      // Supabase için snake_case
      return {
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'created_at': task.createdAt.toIso8601String(),
        'expires_at': task.expiresAt.toIso8601String(),
        'status': task.status.toString(),
      };
    }
    
    // Local database için camelCase
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'createdAt': task.createdAt.toIso8601String(),
      'expiresAt': task.expiresAt.toIso8601String(),
      'status': task.status.toString(),
      'addToCalendar': task.addToCalendar ? 1 : 0,
    };
  }

  static DailyTask _taskFromMap(Map<String, dynamic> map) {
    // Supabase'den gelen data snake_case olabilir
    final id = map['id']?.toString() ?? '';
    final title = map['title']?.toString() ?? '';
    final description = map['description']?.toString() ?? '';
    final createdAtStr = map['createdAt'] ?? map['created_at'];
    final expiresAtStr = map['expiresAt'] ?? map['expires_at'];
    final statusStr = map['status']?.toString() ?? 'TaskStatus.pending';
    final addToCalendar = map['addToCalendar'] == 1 || map['add_to_calendar'] == true || map['add_to_calendar'] == 1;
    
    return DailyTask(
      id: id,
      title: title,
      description: description,
      createdAt: DateTime.parse(createdAtStr.toString()),
      expiresAt: DateTime.parse(expiresAtStr.toString()),
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == statusStr,
        orElse: () => TaskStatus.pending,
      ),
      addToCalendar: addToCalendar,
    );
  }

  static TimeOfDay? _parseTimeOfDay(String timeString) {
    if (timeString.isEmpty) return null;
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static Map<String, dynamic> _noteToMap(DailyNote note, bool completed, int minutesSpent, {bool forCloud = false}) {
    if (forCloud) {
      // Supabase için snake_case
      return {
        'id': note.id,
        'motivation_id': note.motivationId,
        'date': note.date.toIso8601String(),
        'note': note.note,
        'mood': note.mood,
        'tags': note.tags.join(','),
        'completed': completed ? 1 : 0,
        'minutes_spent': minutesSpent,
      };
    }
    
    // Local database için camelCase
    return {
      'id': note.id,
      'motivationId': note.motivationId,
      'date': note.date.toIso8601String(),
      'note': note.note,
      'mood': note.mood,
      'tags': note.tags.join(','),
      'completed': completed ? 1 : 0,
      'minutesSpent': minutesSpent,
    };
  }

  static DailyNote _noteFromMap(Map<String, dynamic> map) {
    // Supabase'den gelen data snake_case olabilir
    final id = map['id']?.toString() ?? '';
    final motivationId = map['motivationId'] ?? map['motivation_id'] ?? '';
    final dateStr = map['date']?.toString() ?? DateTime.now().toIso8601String();
    final note = map['note']?.toString() ?? '';
    final mood = (map['mood'] ?? 3) as int;
    final tagsStr = map['tags']?.toString() ?? '';
    
    return DailyNote(
      id: id,
      motivationId: motivationId.toString(),
      date: DateTime.parse(dateStr),
      note: note,
      mood: mood,
      tags: tagsStr.isNotEmpty ? tagsStr.split(',') : [],
    );
  }
}