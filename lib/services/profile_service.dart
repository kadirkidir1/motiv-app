import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class ProfileService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get user profile
  static Future<UserProfile?> getProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        return UserProfile.fromJson(response);
      }
      
      // If no profile exists, create one
      return await _createProfile(user);
    } catch (e) {
      throw Exception('Failed to get profile: ${e.toString()}');
    }
  }

  // Create new profile
  static Future<UserProfile> _createProfile(User user) async {
    try {
      final profile = UserProfile(
        id: user.id,
        email: user.email!,
        createdAt: DateTime.now(),
      );

      await _supabase.from('profiles').insert(profile.toJson());
      return profile;
    } catch (e) {
      throw Exception('Failed to create profile: ${e.toString()}');
    }
  }

  // Update user profile
  static Future<void> updateProfile(UserProfile profile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('profiles')
          .upsert(profile.toJson())
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Delete profile
  static Future<void> deleteProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('profiles')
          .delete()
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Failed to delete profile: ${e.toString()}');
    }
  }
}