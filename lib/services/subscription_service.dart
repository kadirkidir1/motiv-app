import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

class SubscriptionService {
  static final _supabase = Supabase.instance.client;

  static Future<bool> isPremium() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('subscription_type, premium_until')
          .eq('id', userId)
          .single();

      final subscriptionType = response['subscription_type'] as String?;
      final premiumUntil = response['premium_until'] as String?;

      if (subscriptionType == 'premium' && premiumUntil != null) {
        final expiryDate = DateTime.parse(premiumUntil);
        return DateTime.now().isBefore(expiryDate);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<DateTime?> getPremiumExpiryDate() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select('premium_until')
          .eq('id', userId)
          .single();

      final premiumUntil = response['premium_until'] as String?;
      return premiumUntil != null ? DateTime.parse(premiumUntil) : null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> activatePremium({int months = 1}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final newExpiryDate = DateTime.now().add(Duration(days: 30 * months));

    await _supabase.from('profiles').update({
      'subscription_type': 'premium',
      'premium_until': newExpiryDate.toIso8601String(),
    }).eq('id', userId);
  }

  static Future<int> getMotivationCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        // Offline - local database'den say
        final db = await DatabaseService.database;
        final result = await db.query('motivations');
        return result.length;
      }

      // Online - Supabase'den say
      final response = await _supabase
          .from('motivations')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      try {
        final db = await DatabaseService.database;
        final result = await db.query('motivations');
        return result.length;
      } catch (_) {
        return 0;
      }
    }
  }

  static Future<bool> canAddMotivation() async {
    final isPremiumUser = await isPremium();
    if (isPremiumUser) return true;

    final count = await getMotivationCount();
    return count < 3;
  }

  static Future<int> getTaskCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        final db = await DatabaseService.database;
        final result = await db.query('daily_tasks');
        return result.length;
      }

      final response = await _supabase
          .from('daily_tasks')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      try {
        final db = await DatabaseService.database;
        final result = await db.query('daily_tasks');
        return result.length;
      } catch (_) {
        return 0;
      }
    }
  }

  static Future<bool> canAddTask() async {
    final isPremiumUser = await isPremium();
    if (isPremiumUser) return true;

    final count = await getTaskCount();
    return count < 2;
  }

  static String getFeatureName(String feature, String languageCode) {
    final features = {
      'unlimited_motivations': {
        'tr': 'Sınırsız Motivasyon',
        'en': 'Unlimited Motivations'
      },
      'daily_tasks': {'tr': 'Günlük Görevler', 'en': 'Daily Tasks'},
      'advanced_stats': {'tr': 'Detaylı İstatistikler', 'en': 'Advanced Statistics'},
      'calendar_view': {'tr': 'Takvim Görünümü', 'en': 'Calendar View'},
      'cloud_sync': {'tr': 'Bulut Senkronizasyonu', 'en': 'Cloud Sync'},
    };

    return features[feature]?[languageCode] ?? feature;
  }
}
