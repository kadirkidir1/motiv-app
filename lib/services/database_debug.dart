import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class DatabaseDebug {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> testConnection() async {
    final user = _supabase.auth.currentUser;
    developer.log('Current User: ${user?.id}', name: 'DatabaseDebug');
    developer.log('User Email: ${user?.email}', name: 'DatabaseDebug');
  }

  static Future<void> checkMotivations() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      developer.log('No user logged in', name: 'DatabaseDebug');
      return;
    }

    try {
      final response = await _supabase
          .from('motivations')
          .select()
          .eq('user_id', user.id);
      
      developer.log('Motivations count: ${response.length}', name: 'DatabaseDebug');
      for (var item in response) {
        developer.log('Motivation: ${item['title']}', name: 'DatabaseDebug');
      }
    } catch (e) {
      developer.log('Error checking motivations: $e', name: 'DatabaseDebug');
    }
  }

  static Future<void> checkTasks() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      developer.log('No user logged in', name: 'DatabaseDebug');
      return;
    }

    try {
      final response = await _supabase
          .from('daily_tasks')
          .select()
          .eq('user_id', user.id);
      
      developer.log('Tasks count: ${response.length}', name: 'DatabaseDebug');
      for (var item in response) {
        developer.log('Task: ${item['title']}', name: 'DatabaseDebug');
      }
    } catch (e) {
      developer.log('Error checking tasks: $e', name: 'DatabaseDebug');
    }
  }

  static Future<void> checkNotes() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      developer.log('No user logged in', name: 'DatabaseDebug');
      return;
    }

    try {
      final response = await _supabase
          .from('daily_notes')
          .select()
          .eq('user_id', user.id);
      
      developer.log('Notes count: ${response.length}', name: 'DatabaseDebug');
    } catch (e) {
      developer.log('Error checking notes: $e', name: 'DatabaseDebug');
    }
  }

  static Future<void> runFullCheck() async {
    developer.log('=== Starting Database Debug ===', name: 'DatabaseDebug');
    await testConnection();
    await checkMotivations();
    await checkTasks();
    await checkNotes();
    developer.log('=== Database Debug Complete ===', name: 'DatabaseDebug');
  }
}
