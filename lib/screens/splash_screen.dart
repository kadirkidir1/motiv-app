import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';
import '../services/motivation_quotes.dart';
import '../services/language_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/database_service.dart';
import '../services/database_debug.dart';
import 'dart:developer' as developer;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  MotivationQuote? dailyQuote;
  String languageCode = 'tr';

  @override
  void initState() {
    super.initState();
    _loadLanguageAndQuote();
    _navigateToLogin();
  }

  _loadLanguageAndQuote() async {
    languageCode = await LanguageService.getLanguage();
    dailyQuote = MotivationQuotes.getDailyQuote();
    if (mounted) {
      setState(() {});
    }
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Check if user should be remembered
      final shouldRemember = await AuthService.shouldRememberUser();
      final isSignedIn = AuthService.isSignedIn();

      if (mounted) {
        if (isSignedIn && shouldRemember) {
          // User is signed in and should be remembered
          developer.log('User is signed in, syncing from cloud...', name: 'SplashScreen');
          
          // Debug: Check cloud data before sync
          await DatabaseDebug.runFullCheck();
          
          // Sync data from cloud
          try {
            await DatabaseService.syncFromCloud();
            developer.log('Sync completed successfully', name: 'SplashScreen');
          } catch (e) {
            developer.log('Sync error: $e', name: 'SplashScreen');
          }
          
          // Check if profile is complete
          final profile = await ProfileService.getProfile();

          if (mounted) {
            if (profile?.fullName == null || profile?.age == null ||
                profile?.country == null || profile?.city == null) {
              // Profile incomplete, go to setup
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileSetupScreen(
                    email: AuthService.getCurrentUser()!.email!,
                  ),
                ),
              );
            } else {
              // Profile complete, go to home
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          }
        } else {
          // Go to login screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade600,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/MotivAppUse.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.get('app_name', languageCode),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.get('app_subtitle', languageCode),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: dailyQuote != null
                    ? Column(
                        children: [
                          Text(
                            '"${dailyQuote!.getQuote(languageCode)}"',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '- ${dailyQuote!.author}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(
                        color: Colors.white,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}