import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/routine.dart';
import '../models/daily_task.dart';
import '../models/daily_note.dart';
import 'notification_service.dart';

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
      version: 6,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_notes(
          id TEXT PRIMARY KEY,
          routineId TEXT NOT NULL,
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
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE motivations ADD COLUMN isTimeBased INTEGER DEFAULT 1');
    }
    if (oldVersion < 4) {
      // Rename motivations to routines
      await db.execute('ALTER TABLE motivations RENAME TO routines');
      // Add new columns to daily_tasks
      await db.execute('ALTER TABLE daily_tasks ADD COLUMN hasAlarm INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE daily_tasks ADD COLUMN alarmTime TEXT');
      await db.execute('ALTER TABLE daily_tasks ADD COLUMN deadlineType TEXT DEFAULT "TaskDeadlineType.hours"');
    }
    if (oldVersion < 5) {
      // Create routine_completions table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS routine_completions(
          id TEXT PRIMARY KEY,
          routineId TEXT NOT NULL,
          date TEXT NOT NULL,
          completedAt TEXT NOT NULL,
          minutesSpent INTEGER DEFAULT 0,
          notes TEXT,
          syncedToCloud INTEGER DEFAULT 0,
          UNIQUE(routineId, date)
        )
      ''');
      
      // Create task_completions table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS task_completions(
          id TEXT PRIMARY KEY,
          taskId TEXT NOT NULL,
          completedAt TEXT NOT NULL,
          completionTimeMinutes INTEGER,
          notes TEXT,
          syncedToCloud INTEGER DEFAULT 0
        )
      ''');
      
      // Migrate existing daily_notes data to routine_completions
      await db.execute('''
        INSERT INTO routine_completions (id, routineId, date, completedAt, minutesSpent, notes)
        SELECT id, routineId, date, date, minutesSpent, note
        FROM daily_notes
        WHERE completed = 1
      ''');
      
      // Drop completed and minutesSpent columns from daily_notes
      // SQLite doesn't support DROP COLUMN, so we need to recreate the table
      await db.execute('''
        CREATE TABLE daily_notes_new(
          id TEXT PRIMARY KEY,
          routineId TEXT NOT NULL,
          date TEXT NOT NULL,
          note TEXT,
          mood INTEGER NOT NULL,
          tags TEXT,
          syncedToCloud INTEGER DEFAULT 0
        )
      ''');
      
      await db.execute('''
        INSERT INTO daily_notes_new (id, routineId, date, note, mood, tags, syncedToCloud)
        SELECT id, routineId, date, note, mood, tags, syncedToCloud
        FROM daily_notes
      ''');
      
      await db.execute('DROP TABLE daily_notes');
      await db.execute('ALTER TABLE daily_notes_new RENAME TO daily_notes');
      
      // Add isArchived column to routines
      await db.execute('ALTER TABLE routines ADD COLUMN isArchived INTEGER DEFAULT 0');
      
      // Add completedAt column to daily_tasks
      await db.execute('ALTER TABLE daily_tasks ADD COLUMN completedAt TEXT');
    }
    if (oldVersion < 6) {
      // Add customNotificationMessage to routines and daily_tasks
      await db.execute('ALTER TABLE routines ADD COLUMN customNotificationMessage TEXT');
      await db.execute('ALTER TABLE daily_tasks ADD COLUMN customNotificationMessage TEXT');
    }
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE routines(
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
        isTimeBased INTEGER DEFAULT 1,
        customNotificationMessage TEXT,
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
        hasAlarm INTEGER DEFAULT 0,
        alarmTime TEXT,
        deadlineType TEXT DEFAULT 'TaskDeadlineType.hours',
        customNotificationMessage TEXT,
        syncedToCloud INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_notes(
        id TEXT PRIMARY KEY,
        routineId TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        mood INTEGER NOT NULL,
        tags TEXT,
        syncedToCloud INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE routine_completions(
        id TEXT PRIMARY KEY,
        routineId TEXT NOT NULL,
        date TEXT NOT NULL,
        completedAt TEXT NOT NULL,
        minutesSpent INTEGER DEFAULT 0,
        notes TEXT,
        syncedToCloud INTEGER DEFAULT 0,
        UNIQUE(routineId, date)
      )
    ''');

    await db.execute('''
      CREATE TABLE task_completions(
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        completedAt TEXT NOT NULL,
        completionTimeMinutes INTEGER,
        notes TEXT,
        syncedToCloud INTEGER DEFAULT 0
      )
    ''');
  }

  // Motivations CRUD
  static Future<void> insertRoutine(Routine routine) async {
    final db = await database;
    await db.insert('routines', _routineToMap(routine));
    _syncRoutineToCloud(routine);
  }

  static Future<List<Routine>> getRoutines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('routines');
    return List.generate(maps.length, (i) => _routineFromMap(maps[i]));
  }

  static Future<void> updateRoutine(Routine routine) async {
    final db = await database;
    await db.update(
      'routines',
      _routineToMap(routine),
      where: 'id = ?',
      whereArgs: [routine.id],
    );
    _syncRoutineToCloud(routine);
    
    // Önce eski bildirimi iptal et
    try {
      await NotificationService.cancelMotivationNotification(routine.id);
    } catch (e) {
      developer.log('Notification cancel error: $e', name: 'DatabaseService');
    }
    
    // Bildirim varsa yeniden zamanla
    if (routine.hasAlarm && routine.alarmTime != null) {
      try {
        await NotificationService.scheduleMotivationReminder(
          routine.id,
          routine.title,
          routine.alarmTime!,
          routine.isTimeBased,
          customMessage: routine.customNotificationMessage,
        );
      } catch (e) {
        developer.log('Notification scheduling error: $e', name: 'DatabaseService');
      }
    }
  }

  static Future<void> deleteRoutine(String id) async {
    final db = await database;
    // Önce motivasyona ait notları sil
    await db.delete('daily_notes', where: 'routineId = ?', whereArgs: [id]);
    // Sonra motivasyonu sil
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
    _deleteRoutineFromCloud(id);
    // Cloud'dan notları da sil
    _deleteRoutineNotesFromCloud(id);
  }

  static Future<void> deleteRoutineOnly(String id) async {
    final db = await database;
    // Sadece motivasyonu sil, notları koru
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
    _deleteRoutineFromCloud(id);
  }

  static Future<void> clearAllRoutines() async {
    final db = await database;
    await db.delete('routines');
    
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase
            .from('routines')
            .delete()
            .eq('user_id', user.id);
      } catch (e) {
        developer.log('Cloud clear error: $e', name: 'DatabaseService');
      }
    }
  }

  static Future<void> translateExistingRoutines(String languageCode) async {
    final motivations = await getRoutines();
    
    for (final routine in motivations) {
      String translatedTitle = routine.title;
      String translatedDescription = routine.description;
      
      // Check if this is a predefined routine that needs translation
      if (_isPredefinedMotivation(routine.title)) {
        final translations = _getPredefinedTranslations(routine.title, languageCode);
        if (translations != null) {
          translatedTitle = translations['title'] ?? routine.title;
          translatedDescription = translations['description'] ?? routine.description;
          
          final updatedMotivation = routine.copyWith(
            title: translatedTitle,
            description: translatedDescription,
          );
          
          await updateRoutine(updatedMotivation);
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
  static Future<void> insertDailyNote(DailyNote note) async {
    final db = await database;
    await db.insert('daily_notes', _noteToMap(note));
    _syncNoteToCloud(note);
  }

  static Future<List<DailyNote>> getDailyNotes(String routineId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_notes',
      where: 'routineId = ?',
      whereArgs: [routineId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => _noteFromMap(maps[i]));
  }

  static Future<void> updateDailyNote(DailyNote note) async {
    final db = await database;
    await db.update(
      'daily_notes',
      _noteToMap(note),
      where: 'id = ?',
      whereArgs: [note.id],
    );
    _syncNoteToCloud(note);
  }

  static Future<void> deleteDailyNote(String id) async {
    final db = await database;
    await db.delete('daily_notes', where: 'id = ?', whereArgs: [id]);
    _deleteNoteFromCloud(id);
  }

  // Supabase Sync Methods
  static Future<void> _syncRoutineToCloud(Routine routine) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      developer.log('❌ No user logged in, skipping cloud sync', name: 'DatabaseService');
      return;
    }

    try {
      final motivationData = _routineToMap(routine, forCloud: true);
      motivationData['user_id'] = user.id;
      motivationData.remove('syncedToCloud');
      
      developer.log('📤 Syncing routine: ${routine.title} (ID: ${routine.id})', name: 'DatabaseService');
      developer.log('📦 Data: $motivationData', name: 'DatabaseService');
      
      final response = await _supabase
          .from('routines')
          .upsert(motivationData)
          .select();
      
      developer.log('✅ Routine synced successfully: $response', name: 'DatabaseService');
    } catch (e, stackTrace) {
      developer.log('❌ Routine cloud sync error: $e', name: 'DatabaseService');
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

  static Future<void> _deleteRoutineFromCloud(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('routines')
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

  static Future<void> _syncNoteToCloud(DailyNote note) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      developer.log('❌ No user logged in, skipping cloud sync', name: 'DatabaseService');
      return;
    }

    try {
      final noteData = _noteToMap(note, forCloud: true);
      noteData['user_id'] = user.id;
      noteData.remove('syncedToCloud');
      
      developer.log('📤 Syncing note: ${note.id} for routine: ${note.routineId}', name: 'DatabaseService');
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

  static Future<void> _deleteRoutineNotesFromCloud(String routineId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('daily_notes')
          .delete()
          .eq('routine_id', routineId)
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
      await db.delete('routines');
      await db.delete('daily_tasks');
      await db.delete('daily_notes');
      
      // Sync motivations
      developer.log('📥 Fetching motivations from cloud...', name: 'DatabaseService');
      final motivationsResponse = await _supabase
          .from('routines')
          .select()
          .eq('user_id', user.id);

      developer.log('📊 Found ${motivationsResponse.length} motivations in cloud', name: 'DatabaseService');
      
      for (var data in motivationsResponse) {
          developer.log('📦 Routine data from cloud: $data', name: 'DatabaseService');
          final routine = _routineFromMap(data);
          await db.insert(
            'routines',
            _routineToMap(routine),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          developer.log('✅ Synced routine: ${routine.title}', name: 'DatabaseService');
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
          await db.insert(
            'daily_notes',
            _noteToMap(note),
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
  static Map<String, dynamic> _routineToMap(Routine routine, {bool forCloud = false}) {
    if (forCloud) {
      return {
        'id': routine.id,
        'title': routine.title,
        'description': routine.description,
        'category': routine.category.toString(),
        'frequency': routine.frequency.toString(),
        'has_alarm': routine.hasAlarm ? 1 : 0,
        'alarm_time': routine.alarmTime != null ? '${routine.alarmTime!.hour}:${routine.alarmTime!.minute.toString().padLeft(2, '0')}' : null,
        'created_at': routine.createdAt.toIso8601String(),
        'is_completed': routine.isCompleted ? 1 : 0,
        'target_minutes': routine.targetMinutes,
        'is_time_based': routine.isTimeBased ? 1 : 0,
        'custom_notification_message': routine.customNotificationMessage,
      };
    }
    
    return {
      'id': routine.id,
      'title': routine.title,
      'description': routine.description,
      'category': routine.category.toString(),
      'frequency': routine.frequency.toString(),
      'hasAlarm': routine.hasAlarm ? 1 : 0,
      'alarmTime': routine.alarmTime != null ? '${routine.alarmTime!.hour}:${routine.alarmTime!.minute.toString().padLeft(2, '0')}' : null,
      'createdAt': routine.createdAt.toIso8601String(),
      'isCompleted': routine.isCompleted ? 1 : 0,
      'targetMinutes': routine.targetMinutes,
      'isTimeBased': routine.isTimeBased ? 1 : 0,
      'customNotificationMessage': routine.customNotificationMessage,
    };
  }

  static Routine _routineFromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString() ?? '';
    final title = map['title']?.toString() ?? '';
    final description = map['description']?.toString() ?? '';
    final categoryStr = map['category']?.toString() ?? 'RoutineCategory.personal';
    final frequencyStr = map['frequency']?.toString() ?? 'RoutineFrequency.daily';
    final hasAlarm = map['hasAlarm'] == 1 || map['has_alarm'] == true || map['has_alarm'] == 1;
    final alarmTimeStr = map['alarmTime'] ?? map['alarm_time'];
    
    // Debug log
    if (alarmTimeStr != null) {
      developer.log('Parsing alarm_time: $alarmTimeStr for routine: $title', name: 'DatabaseService');
    }
    final createdAtStr = map['createdAt'] ?? map['created_at'];
    final isCompleted = map['isCompleted'] == 1 || map['is_completed'] == true || map['is_completed'] == 1;
    final targetMinutes = (map['targetMinutes'] ?? map['target_minutes'] ?? 0) as int;
    final isTimeBasedValue = map['isTimeBased'] ?? map['is_time_based'];
    final isTimeBased = isTimeBasedValue == 1 || isTimeBasedValue == true || (isTimeBasedValue == null && targetMinutes > 0);
    final customNotificationMessage = map['customNotificationMessage'] ?? map['custom_notification_message'];
    
    return Routine(
      id: id,
      title: title,
      description: description,
      category: RoutineCategory.values.firstWhere(
        (e) => e.toString() == categoryStr,
        orElse: () => RoutineCategory.personal,
      ),
      frequency: RoutineFrequency.values.firstWhere(
        (e) => e.toString() == frequencyStr,
        orElse: () => RoutineFrequency.daily,
      ),
      hasAlarm: hasAlarm,
      alarmTime: alarmTimeStr != null ? _parseTimeOfDay(alarmTimeStr.toString()) : null,
      createdAt: DateTime.parse(createdAtStr.toString()),
      isCompleted: isCompleted,
      targetMinutes: targetMinutes,
      isTimeBased: isTimeBased,
      customNotificationMessage: customNotificationMessage?.toString(),
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
        'add_to_calendar': task.addToCalendar,
        'has_alarm': task.hasAlarm ? 1 : 0,
        'alarm_time': task.alarmTime?.toIso8601String(),
        'deadline_type': task.deadlineType.toString(),
        'custom_notification_message': task.customNotificationMessage,
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
      'hasAlarm': task.hasAlarm ? 1 : 0,
      'alarmTime': task.alarmTime?.toIso8601String(),
      'deadlineType': task.deadlineType.toString(),
      'customNotificationMessage': task.customNotificationMessage,
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
    final hasAlarm = map['hasAlarm'] == 1 || map['has_alarm'] == true || map['has_alarm'] == 1;
    final alarmTimeStr = map['alarmTime'] ?? map['alarm_time'];
    final deadlineTypeStr = map['deadlineType'] ?? map['deadline_type'] ?? 'TaskDeadlineType.hours';
    final customNotificationMessage = map['customNotificationMessage'] ?? map['custom_notification_message'];
    
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
      hasAlarm: hasAlarm,
      alarmTime: alarmTimeStr != null ? DateTime.tryParse(alarmTimeStr.toString()) : null,
      deadlineType: TaskDeadlineType.values.firstWhere(
        (e) => e.toString() == deadlineTypeStr,
        orElse: () => TaskDeadlineType.hours,
      ),
      customNotificationMessage: customNotificationMessage?.toString(),
    );
  }

  static TimeOfDay? _parseTimeOfDay(String timeString) {
    if (timeString.isEmpty || timeString.contains('Instance of')) return null;
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic> _noteToMap(DailyNote note, {bool forCloud = false}) {
    if (forCloud) {
      // Supabase için snake_case
      return {
        'id': note.id,
        'routine_id': note.routineId,
        'date': note.date.toIso8601String(),
        'note': note.note,
        'mood': note.mood,
        'tags': note.tags.join(','),
      };
    }
    
    // Local database için camelCase
    return {
      'id': note.id,
      'routineId': note.routineId,
      'date': note.date.toIso8601String(),
      'note': note.note,
      'mood': note.mood,
      'tags': note.tags.join(','),
    };
  }

  static DailyNote _noteFromMap(Map<String, dynamic> map) {
    // Supabase'den gelen data snake_case olabilir
    final id = map['id']?.toString() ?? '';
    final routineId = map['routineId'] ?? map['routine_id'] ?? '';
    final dateStr = map['date']?.toString() ?? DateTime.now().toIso8601String();
    final note = map['note']?.toString();
    final mood = (map['mood'] ?? 3) as int;
    final tagsStr = map['tags']?.toString() ?? '';
    
    return DailyNote(
      id: id,
      routineId: routineId.toString(),
      date: DateTime.parse(dateStr),
      note: note,
      mood: mood,
      tags: tagsStr.isNotEmpty ? tagsStr.split(',') : [],
    );
  }
}