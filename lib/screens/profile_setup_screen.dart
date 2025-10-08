import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/location_service.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  
  String? _selectedCountry;
  String? _selectedCity;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.person_add,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.get('complete_profile', _languageCode),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.get('profile_subtitle', _languageCode),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              
              // İsim
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.get('full_name', _languageCode),
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.get('name_required', _languageCode);
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Yaş
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
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.get('age_required', _languageCode);
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 13 || age > 120) {
                    return AppLocalizations.get('age_invalid', _languageCode);
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Ülke
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
                  if (value == null) {
                    return AppLocalizations.get('country_required', _languageCode);
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Şehir
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
                  if (value == null) {
                    return AppLocalizations.get('city_required', _languageCode);
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 40),
              
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
                    AppLocalizations.get('complete_setup', _languageCode),
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
    if (_formKey.currentState!.validate()) {
      try {
        final user = AuthService.getCurrentUser();
        if (user == null) {
          throw Exception('Kullanıcı bulunamadı. Lütfen tekrar giriş yapın.');
        }

        final newProfile = UserProfile(
          id: user.id,
          email: widget.email,
          fullName: _nameController.text.trim(),
          age: int.parse(_ageController.text),
          country: _selectedCountry,
          city: _selectedCity,
          createdAt: DateTime.now(),
        );

        await ProfileService.updateProfile(newProfile);

        // Profili kaydet ve ana ekrana git
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

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}