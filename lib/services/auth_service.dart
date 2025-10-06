import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _rememberMeKey = 'remember_me';
  static const String _lastLoginKey = 'last_login';

  // Email/Password Sign Up
  static Future<void> signUp(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // User created successfully, email verification required
        return;
      } else {
        throw Exception('Sign up failed');
      }
    } catch (e) {
      throw Exception('Sign up error: ${e.toString()}');
    }
  }

  // Email/Password Sign In
  static Future<void> signIn(String email, String password, {bool rememberMe = false}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Save remember me preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_rememberMeKey, rememberMe);
        if (rememberMe) {
          await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
        }
        
        // Sync data from cloud
        await DatabaseService.syncFromCloud();
        return;
      } else {
        throw Exception('Sign in failed');
      }
    } catch (e) {
      throw Exception('Sign in error: ${e.toString()}');
    }
  }

  // Google Sign In
  static Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.motivapp://login-callback/',
      );
      
      // Note: For mobile apps, you'll need to handle the OAuth flow differently
      // This is a simplified version
      throw Exception('Google Sign-In requires additional setup for mobile apps');
    } catch (e) {
      throw Exception('Google sign in error: ${e.toString()}');
    }
  }

  // Sign Out
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      
      // Clear remember me preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rememberMeKey);
      await prefs.remove(_lastLoginKey);
    } catch (e) {
      throw Exception('Sign out error: ${e.toString()}');
    }
  }

  // Check if user is signed in
  static bool isSignedIn() {
    return _supabase.auth.currentUser != null;
  }

  // Get current user
  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Check if should remember user (30 days)
  static Future<bool> shouldRememberUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      
      if (!rememberMe) return false;
      
      final lastLoginStr = prefs.getString(_lastLoginKey);
      if (lastLoginStr == null) return false;
      
      final lastLogin = DateTime.parse(lastLoginStr);
      final daysSinceLogin = DateTime.now().difference(lastLogin).inDays;
      
      // Remember for 30 days
      return daysSinceLogin < 30;
    } catch (e) {
      return false;
    }
  }

  // Reset Password
  static Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset error: ${e.toString()}');
    }
  }

  // Listen to auth state changes
  static Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }
}