import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'language_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  
  // Bildirim aksiyonları için stream
  static final _notificationActionController = StreamController<String>.broadcast();
  static Stream<String> get notificationStream => _notificationActionController.stream;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {


      // Timezone ayarları
      tz.initializeTimeZones();
      final location = tz.getLocation('Europe/Istanbul');
      tz.setLocalLocation(location);


      // Android initialization
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );

      const settings = InitializationSettings(android: android, iOS: ios);

      // Initialize plugin
      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Android izinleri
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Bildirim izni
        await androidPlugin.requestNotificationsPermission();


        // Exact alarm izni (Android 12+)
        await androidPlugin.requestExactAlarmsPermission();


        // Bildirim kanallarını oluştur
        await _createNotificationChannels(androidPlugin);
      }

      _initialized = true;

    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _createNotificationChannels(
      AndroidFlutterLocalNotificationsPlugin androidPlugin) async {
    try {
      // Daily Summary Channel
      await androidPlugin
          .createNotificationChannel(const AndroidNotificationChannel(
        'daily_summary',
        'Günlük Özet',
        description: 'Günlük görev özeti bildirimleri',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ));

      // Evening Summary Channel
      await androidPlugin
          .createNotificationChannel(const AndroidNotificationChannel(
        'evening_summary',
        'Akşam Özeti',
        description: 'Akşam görev özeti bildirimleri',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ));

      // Streak Reminder Channel
      await androidPlugin
          .createNotificationChannel(const AndroidNotificationChannel(
        'streak_reminder',
        'Seri Hatırlatıcısı',
        description: 'Günlük seri hatırlatma bildirimleri',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ));

      // Task Reminder Channel
      await androidPlugin
          .createNotificationChannel(const AndroidNotificationChannel(
        'task_reminder',
        'Görev Hatırlatıcısı',
        description: 'Görev ve rutin hatırlatma bildirimleri',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ));

    } catch (e) {
      // Ignore channel creation errors
    }
  }

  static void _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {}

  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Payload'ı global bir stream'e gönder
      _notificationActionController.add(payload);
    }
  }

  static Future<bool> canScheduleExactAlarms() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  static Future<bool> _checkInitialization() async {
    if (!_initialized) {
      await initialize();
    }
    return _initialized;
  }

  static Future<void> scheduleDailySummary(TimeOfDay time) async {
    try {
      await _checkInitialization();

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final delaySeconds = scheduledDate.difference(now).inSeconds;
      final lang = await LanguageService.getLanguage();
      final title = lang == 'tr' ? 'Günaydın! 🌅' : 'Good Morning! 🌅';
      final body = lang == 'tr' ? 'Bugünkü görevlerin seni bekliyor!' : 'Your tasks are waiting for you today!';

      if (Platform.isAndroid) {
        const platform = MethodChannel('com.motivapp.motivapp/alarm');
        await platform.invokeMethod('scheduleAlarm', {
          'delaySeconds': delaySeconds,
          'title': title,
          'body': body,
        });
      } else {
        await _notifications.cancel(1);
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

        await _notifications.zonedSchedule(
          1,
          title,
          body,
          tzScheduledDate,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              sound: 'default',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_summary_hour', time.hour);
      await prefs.setInt('daily_summary_minute', time.minute);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> scheduleEveningSummary(TimeOfDay time) async {
    try {
      await _checkInitialization();

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final delaySeconds = scheduledDate.difference(now).inSeconds;
      final lang = await LanguageService.getLanguage();
      final title = lang == 'tr' ? 'Gün Sonu Özeti 🌙' : 'End of Day Summary 🌙';
      final body = lang == 'tr' ? 'Bugün harika işler başardın!' : 'You did great things today!';

      if (Platform.isAndroid) {
        const platform = MethodChannel('com.motivapp.motivapp/alarm');
        await platform.invokeMethod('scheduleAlarm', {
          'delaySeconds': delaySeconds,
          'title': title,
          'body': body,
        });
      } else {
        await _notifications.cancel(2);
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

        await _notifications.zonedSchedule(
          2,
          title,
          body,
          tzScheduledDate,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              sound: 'default',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('evening_summary_hour', time.hour);
      await prefs.setInt('evening_summary_minute', time.minute);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> scheduleStreakReminder(TimeOfDay time) async {
    try {
      await _checkInitialization();

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final delaySeconds = scheduledDate.difference(now).inSeconds;
      final lang = await LanguageService.getLanguage();
      final title = lang == 'tr' ? 'Serinizi Koruyun! 🔥' : 'Keep Your Streak! 🔥';
      final body = lang == 'tr' ? 'Bugün hiç görev tamamlamadınız. Hemen başlayın!' : 'You haven\'t completed any tasks today. Start now!';

      if (Platform.isAndroid) {
        const platform = MethodChannel('com.motivapp.motivapp/alarm');
        await platform.invokeMethod('scheduleAlarm', {
          'delaySeconds': delaySeconds,
          'title': title,
          'body': body,
        });
      } else {
        await _notifications.cancel(3);
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

        await _notifications.zonedSchedule(
          3,
          title,
          body,
          tzScheduledDate,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              sound: 'default',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('streak_reminder_hour', time.hour);
      await prefs.setInt('streak_reminder_minute', time.minute);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> setReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_minutes', minutes);
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (!enabled) {
      await _notifications.cancelAll();
    }
  }

  static Future<TimeOfDay> getDailySummaryTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('daily_summary_hour') ?? 8;
    final minute = prefs.getInt('daily_summary_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static Future<TimeOfDay> getEveningSummaryTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('evening_summary_hour') ?? 20;
    final minute = prefs.getInt('evening_summary_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static Future<TimeOfDay> getStreakReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('streak_reminder_hour') ?? 21;
    final minute = prefs.getInt('streak_reminder_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static Future<int> getReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('reminder_minutes') ?? 30;
  }

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  static Future<void> showTaskReminder(
      String taskTitle, int minutesBefore) async {
    try {
      await _checkInitialization();

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        '⏰ Görev Hatırlatıcısı',
        '$taskTitle - $minutesBefore dakika kaldı!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminder',
            'Görev Hatırlatıcısı',
            channelDescription: 'Görev ve rutin hatırlatma bildirimleri',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            sound: 'default',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'task_reminder_$taskTitle',
      );

    } catch (e) {
      rethrow;
    }
  }

  static Future<void> scheduleTaskReminder(String taskId, String taskTitle, DateTime reminderTime, {String? customMessage}) async {
    try {
      await _checkInitialization();

      final now = DateTime.now();
      if (reminderTime.isBefore(now)) return;

      final delaySeconds = reminderTime.difference(now).inSeconds;
      final lang = await LanguageService.getLanguage();
      final title = customMessage ?? (lang == 'tr' ? 'Görev Hatırlatıcısı ⏰' : 'Task Reminder ⏰');
      final body = customMessage != null ? '' : (lang == 'tr' ? '$taskTitle - Yakında süresi dolacak!' : '$taskTitle - Time is running out!');

      if (Platform.isAndroid) {
        const platform = MethodChannel('com.motivapp.motivapp/alarm');
        await platform.invokeMethod('scheduleAlarm', {
          'delaySeconds': delaySeconds,
          'title': title,
          'body': body,
        });
      } else {
        final tzScheduledDate = tz.TZDateTime.from(reminderTime, tz.local);
        await _notifications.zonedSchedule(
          '${taskId}_reminder'.hashCode,
          title,
          body,
          tzScheduledDate,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              sound: 'default',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'task_reminder_$taskId',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> scheduleTaskExpiration(String taskId, String taskTitle, DateTime expiresAt) async {
    try {
      await _checkInitialization();

      final now = DateTime.now();
      if (expiresAt.isBefore(now)) return;

      final delaySeconds = expiresAt.difference(now).inSeconds;
      final lang = await LanguageService.getLanguage();
      final title = lang == 'tr' ? 'Görev Süresi Doldu ⏰' : 'Task Time Expired ⏰';
      final body = lang == 'tr' ? '$taskTitle - Tamamladınız mı?' : '$taskTitle - Did you complete it?';

      if (Platform.isAndroid) {
        const platform = MethodChannel('com.motivapp.motivapp/alarm');
        await platform.invokeMethod('scheduleAlarm', {
          'delaySeconds': delaySeconds,
          'title': title,
          'body': body,
        });
      } else {
        final tzScheduledDate = tz.TZDateTime.from(expiresAt, tz.local);
        await _notifications.zonedSchedule(
          taskId.hashCode,
          title,
          body,
          tzScheduledDate,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              sound: 'default',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'task_expiration_$taskId',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> cancelTaskNotification(String taskId) async {
    try {
      await _checkInitialization();
      await _notifications.cancel(taskId.hashCode);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> scheduleMotivationReminder(String motivationId, String motivationTitle, TimeOfDay time, bool isTimeBased, {String? customMessage}) async {
    try {
      await _checkInitialization();

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final delaySeconds = scheduledDate.difference(now).inSeconds;
      final lang = await LanguageService.getLanguage();
      
      final title = customMessage ?? '$motivationTitle \u23f0';
      final body = customMessage != null ? '' : (isTimeBased
          ? (lang == 'tr' ? 'Ka\u00e7 dakika harcad\u0131n\u0131z?' : 'How many minutes did you spend?')
          : (lang == 'tr' ? 'Tamamlad\u0131n\u0131z m\u0131?' : 'Did you complete it?'));

      if (Platform.isAndroid) {
        const platform = MethodChannel('com.motivapp.motivapp/alarm');
        await platform.invokeMethod('scheduleAlarm', {
          'delaySeconds': delaySeconds,
          'title': title,
          'body': body,
        });
      } else {
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
        await _notifications.zonedSchedule(
          motivationId.hashCode,
          title,
          body,
          tzScheduledDate,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              sound: 'default',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'motivation_reminder_$motivationId',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> cancelMotivationNotification(String motivationId) async {
    try {
      await _checkInitialization();
      await _notifications.cancel(motivationId.hashCode);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> showInstantNotification() async {
    try {
      await _checkInitialization();

      await _notifications.show(
        999,
        'Anlık Test 🚀',
        'Bu bildirim hemen gösterildi!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminder',
            'Görev Hatırlatıcısı',
            channelDescription: 'Test bildirimleri',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            sound: 'default',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> scheduleTestNotification() async {
    try {
      await _checkInitialization();

      if (Platform.isAndroid) {
        const platform = MethodChannel('com.motivapp.motivapp/alarm');
        await platform.invokeMethod('scheduleAlarm', {
          'delaySeconds': 15,
          'title': 'Native Test 🚀',
          'body': '15 saniye sonra native AlarmManager ile gelen bildirim!',
        });
      } else {
        final scheduledDate = DateTime.now().add(const Duration(seconds: 10));
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

        await _notifications.zonedSchedule(
          999,
          'Test Bildirimi 🚀',
          '10 saniye sonra gelen test bildirimi!',
          tzScheduledDate,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              sound: 'default',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'test_notification',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> rescheduleAllNotifications() async {
    try {
      await _checkInitialization();

      final dailyTime = await getDailySummaryTime();
      final eveningTime = await getEveningSummaryTime();
      final streakTime = await getStreakReminderTime();

      await scheduleDailySummary(dailyTime);
      await scheduleEveningSummary(eveningTime);
      await scheduleStreakReminder(streakTime);

    } catch (e) {
      rethrow;
    }
  }

  // Bekleyen bildirimleri kontrol et
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    await _checkInitialization();
    return await _notifications.pendingNotificationRequests();
  }

  // Tüm bildirimleri temizle
  static Future<void> clearAllNotifications() async {
    await _checkInitialization();
    await _notifications.cancelAll();
  }
}
