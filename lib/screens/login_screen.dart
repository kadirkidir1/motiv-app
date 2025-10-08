import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';
import '../services/language_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/location_service.dart';
import '../models/user_profile.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  String _languageCode = 'tr';
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  String? _selectedCountry;
  String? _selectedCity;

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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/images/MotivAppUse.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.get('login_welcome', _languageCode),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.get('login_subtitle', _languageCode),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildAuthForm(),
              const SizedBox(height: 20),
              _buildGoogleSignIn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: AppLocalizations.get('email', _languageCode),
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.get('email_required', _languageCode);
              }
              if (!value.contains('@')) {
                return AppLocalizations.get('email_invalid', _languageCode);
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: AppLocalizations.get('password', _languageCode),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.get('password_required', _languageCode);
              }
              if (value.length < 6) {
                return AppLocalizations.get('password_min_length', _languageCode);
              }
              return null;
            },
          ),

          // Sign up ek alanları
          if (_isSignUp) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.get('full_name', _languageCode),
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (_isSignUp && (value == null || value.isEmpty)) {
                  return AppLocalizations.get('name_required', _languageCode);
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: InputDecoration(
                labelText: AppLocalizations.get('age', _languageCode),
                prefixIcon: const Icon(Icons.cake),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_isSignUp) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.get('age_required', _languageCode);
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 13 || age > 120) {
                    return AppLocalizations.get('age_invalid', _languageCode);
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedCountry),
              initialValue: _selectedCountry,
              decoration: InputDecoration(
                labelText: AppLocalizations.get('country', _languageCode),
                prefixIcon: const Icon(Icons.flag),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: LocationService.getCountries().map((country) {
                return DropdownMenuItem(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value;
                  _selectedCity = null;
                });
              },
              validator: (value) {
                if (_isSignUp && value == null) {
                  return AppLocalizations.get('country_required', _languageCode);
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey('$_selectedCountry-$_selectedCity'),
              initialValue: _selectedCity,
              decoration: InputDecoration(
                labelText: AppLocalizations.get('city', _languageCode),
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _selectedCountry != null
                  ? LocationService.getCities(_selectedCountry!).map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      );
                    }).toList()
                  : [],
              onChanged: _selectedCountry != null
                  ? (value) {
                      setState(() {
                        _selectedCity = value;
                      });
                    }
                  : null,
              validator: (value) {
                if (_isSignUp && value == null) {
                  return AppLocalizations.get('city_required', _languageCode);
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 16),
          if (!_isSignUp)
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
                Text(AppLocalizations.get('remember_me', _languageCode)),
              ],
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleEmailAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _isSignUp
                          ? AppLocalizations.get('sign_up', _languageCode)
                          : AppLocalizations.get('sign_in', _languageCode),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _isSignUp = !_isSignUp;
              });
            },
            child: Text(
              _isSignUp
                  ? AppLocalizations.get('already_have_account', _languageCode)
                  : AppLocalizations.get('dont_have_account', _languageCode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignIn() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizations.get('or', _languageCode),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _signInWithGoogle,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.account_circle, color: Colors.red),
            label: Text(
              AppLocalizations.get('google_signin', _languageCode),
              style: const TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSignUp) {
        // Profil bilgilerini geçici olarak kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_email', _emailController.text.trim());
        await prefs.setString('pending_fullname', _fullNameController.text.trim());
        await prefs.setInt('pending_age', int.parse(_ageController.text));
        await prefs.setString('pending_country', _selectedCountry!);
        await prefs.setString('pending_city', _selectedCity!);

        // Kayıt ol
        await AuthService.signUp(
          _emailController.text.trim(),
          _passwordController.text,
        );

        // Email doğrulama mesajı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.get('check_email_verification', _languageCode)}\n\nEmail adresinizi doğruladıktan sonra giriş yapabilirsiniz.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 7),
            ),
          );

          // Kayıt formunu temizle ve giriş moduna geç
          setState(() {
            _isSignUp = false;
            _emailController.clear();
            _passwordController.clear();
            _fullNameController.clear();
            _ageController.clear();
            _selectedCountry = null;
            _selectedCity = null;
          });
        }
      } else {
        // Giriş yap
        await AuthService.signIn(
          _emailController.text.trim(),
          _passwordController.text,
          rememberMe: _rememberMe,
        );

        // İlk girişte pending profil bilgilerini kontrol et
        try {
          final prefs = await SharedPreferences.getInstance();
          final pendingEmail = prefs.getString('pending_email');

          if (pendingEmail == _emailController.text.trim()) {
            // Pending profil bilgileri var, Supabase'e kaydet
            final fullName = prefs.getString('pending_fullname');
            final age = prefs.getInt('pending_age');
            final country = prefs.getString('pending_country');
            final city = prefs.getString('pending_city');

            if (fullName != null && age != null && country != null && city != null) {
              final profile = UserProfile(
                id: AuthService.getCurrentUser()!.id,
                email: _emailController.text.trim(),
                fullName: fullName,
                age: age,
                country: country,
                city: city,
                createdAt: DateTime.now(),
              );

              try {
                await ProfileService.updateProfile(profile);

                // Pending bilgileri temizle
                await prefs.remove('pending_email');
                await prefs.remove('pending_fullname');
                await prefs.remove('pending_age');
                await prefs.remove('pending_country');
                await prefs.remove('pending_city');
              } catch (e) {
                // Hata olsa bile devam et
              }
            }
          }
        } catch (e) {
          // Hata olsa bile devam et
        }

        if (mounted) {
          await _navigateBasedOnProfile();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.signInWithGoogle();

      // Check if user is actually signed in
      if (mounted) {
        if (AuthService.isSignedIn()) {
          await _navigateBasedOnProfile();
        } else {
          // User cancelled or something went wrong silently
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _navigateBasedOnProfile() async {
    try {
      final profile = await ProfileService.getProfile();

      if (profile?.fullName == null || profile?.age == null ||
          profile?.country == null || profile?.city == null) {
        // Profile is incomplete, go to setup
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSetupScreen(
                email: AuthService.getCurrentUser()!.email!,
              ),
            ),
          );
        }
      } else {
        // Profile is complete, go to home
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      // If error getting profile, go to setup
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSetupScreen(
              email: AuthService.getCurrentUser()!.email!,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}