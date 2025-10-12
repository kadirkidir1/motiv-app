import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/language_service.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String email;
  
  const ProfileSetupScreen({super.key, required this.email});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String _languageCode = 'tr';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  _loadLanguage() async {
    final language = await LanguageService.getLanguage();
    setState(() {
      _languageCode = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Çıkış yapma onayı
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.get('sign_out', _languageCode)),
            content: const Text('Profil kurulumundan çıkmak istediğinize emin misiniz? Çıkarsanız giriş yapmanız gerekecek.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.get('cancel', _languageCode)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
child: const Text(
                  'Çıkış Yap',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await AuthService.signOut();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(AppLocalizations.get('profile_setup', _languageCode)),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.get('sign_out', _languageCode)),
                  content: const Text('Profil kurulumundan çıkmak istediğinize emin misiniz? Çıkarsanız giriş yapmanız gerekecek.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.get('cancel', _languageCode)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text(
                        'Çıkış Yap',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await AuthService.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 30),
              Text(
                _languageCode == 'tr' ? 'Hoş Geldiniz!' : 'Welcome!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                _languageCode == 'tr' 
                  ? 'Hesabınız başarıyla oluşturuldu.\nHemen başlayalım!'
                  : 'Your account has been created successfully.\nLet\'s get started!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _languageCode == 'tr' ? 'Başlayalım' : 'Get Started',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _saveProfile() async {
    try {
      final user = AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı. Lütfen tekrar giriş yapın.');
      }

      final newProfile = UserProfile(
        id: user.id,
        email: widget.email,
        createdAt: DateTime.now(),
      );

      await ProfileService.updateProfile(newProfile);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }


}