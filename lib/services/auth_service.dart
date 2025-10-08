import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
        // Check if user already exists (Supabase returns existing user)
        if (response.user!.emailConfirmedAt != null) {
          throw Exception('Bu email adresi zaten kayıtlı. Lütfen giriş yapın.');
        }
        // User created successfully, email verification required
        return;
      } else {
        throw Exception('Kayıt başarısız oldu');
      }
    } catch (e) {
      // Check for specific Supabase errors
      if (e.toString().contains('User already registered')) {
        throw Exception('Bu email adresi zaten kayıtlı. Lütfen giriş yapın.');
      }
      if (e.toString().contains('Bu email adresi zaten kayıtlı')) {
        rethrow;
      }
      throw Exception('Kayıt hatası: ${e.toString()}');
    }
  }

  // Email/Password Sign In
  static Future<void> signIn(String email, String password,
      {bool rememberMe = false}) async {
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
          await prefs.setString(
              _lastLoginKey, DateTime.now().toIso8601String());
        }

        // Sync data from cloud
        await DatabaseService.syncFromCloud();
        return;
      } else {
        throw Exception('Kullanıcı Adı ya da Şifre Hatalı');
      }
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('invalid') ||
          errorMsg.contains('credentials') ||
          errorMsg.contains('password') ||
          errorMsg.contains('email')) {
        throw Exception('Kullanıcı Adı ya da Şifre Hatalı');
      }
      throw Exception('Giriş hatası: ${e.toString()}');
    }
  }

  // Google Sign In
  static Future<void> signInWithGoogle() async {
    try {
      const webClientId =
          '300397946654-rl7q0906d66beu4vhks0f45s25ntn5f7.apps.googleusercontent.com';
      const androidClientId =
          '300397946654-vg5kjmsina57lk57nihkje8a370ctj1l.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: androidClientId,
        serverClientId: webClientId,
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google girişi iptal edildi');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Google token alınamadı');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      await DatabaseService.syncFromCloud();
    } catch (e) {
      throw Exception('Google giriş hatası: ${e.toString()}');
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
