import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/subscription_service.dart';
import '../models/user_profile.dart';
import 'login_screen.dart';
import 'premium_screen.dart';

class AccountScreen extends StatefulWidget {
  final String languageCode;

  const AccountScreen({
    super.key,
    required this.languageCode,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();

  String _languageCode = 'tr';
  bool _isLoading = false;
  bool _isEditing = false;
  UserProfile? _profile;
  String? _selectedCountry;
  String? _selectedCity;
  
  bool _notificationsEnabled = true;
  TimeOfDay _dailySummaryTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _eveningSummaryTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _streakReminderTime = const TimeOfDay(hour: 21, minute: 0);
  int _reminderMinutes = 30;

  @override
  void initState() {
    super.initState();
    _languageCode = widget.languageCode;
    _loadProfile();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await NotificationService.getNotificationsEnabled();
    final dailyTime = await NotificationService.getDailySummaryTime();
    final eveningTime = await NotificationService.getEveningSummaryTime();
    final streakTime = await NotificationService.getStreakReminderTime();
    final minutes = await NotificationService.getReminderMinutes();
    
    setState(() {
      _notificationsEnabled = enabled;
      _dailySummaryTime = dailyTime;
      _eveningSummaryTime = eveningTime;
      _streakReminderTime = streakTime;
      _reminderMinutes = minutes;
    });
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await ProfileService.getProfile();
      if (profile != null) {
        setState(() {
          _profile = profile;
          _fullNameController.text = profile.fullName ?? '';
          _ageController.text = profile.age?.toString() ?? '';
          _selectedCountry = profile.country;
          _selectedCity = profile.city;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('error_occurred', _languageCode)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();
    
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: 16),
                  _buildPremiumCard(),
                  const SizedBox(height: 16),
                  // Edit/Save butonu
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isEditing ? _saveProfile : _toggleEdit,
                      icon: Icon(_isEditing ? Icons.save : Icons.edit),
                      label: Text(_isEditing ? 'Kaydet' : 'Düzenle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEditing ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildProfileForm(),
                  const SizedBox(height: 24),
                  _buildNotificationSettings(),
                  const SizedBox(height: 24),
                  _buildAboutSection(),
                  const SizedBox(height: 32),
                  _buildSignOutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _profile?.fullName ?? AppLocalizations.get('no_name', _languageCode),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.get('profile_info', _languageCode),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.get('full_name', _languageCode),
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                ),
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
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
                  border: const OutlineInputBorder(),
                ),
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 120) {
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
                  prefixIcon: const Icon(Icons.public),
                  border: const OutlineInputBorder(),
                ),
                items: LocationService.getCountries().map((country) {
                  return DropdownMenuItem(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: _isEditing ? (value) {
                  setState(() {
                    _selectedCountry = value;
                    _selectedCity = null;
                  });
                } : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('$_selectedCountry-$_selectedCity'),
                initialValue: _selectedCity,
                decoration: InputDecoration(
                  labelText: AppLocalizations.get('city', _languageCode),
                  prefixIcon: const Icon(Icons.location_city),
                  border: const OutlineInputBorder(),
                ),
                items: _selectedCountry != null
                    ? LocationService.getCities(_selectedCountry!).map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        );
                      }).toList()
                    : [],
                onChanged: _isEditing && _selectedCountry != null ? (value) {
                  setState(() {
                    _selectedCity = value;
                  });
                } : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Bildirim Ayarları',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bildirimler uygulama açıldığında otomatik kontrol edilir ve gönderilir.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Bildirimleri Aç'),
              subtitle: const Text('Tüm bildirimleri etkinleştir/kapat'),
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() {
                  _notificationsEnabled = value;
                });
                await NotificationService.setNotificationsEnabled(value);
                if (value) {
                  await NotificationService.scheduleDailySummary(_dailySummaryTime);
                  await NotificationService.scheduleEveningSummary(_eveningSummaryTime);
                  await NotificationService.scheduleStreakReminder(_streakReminderTime);
                }
              },
            ),
            if (_notificationsEnabled) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: const Text('Günlük Özet Saati'),
                subtitle: Text('${_dailySummaryTime.hour.toString().padLeft(2, '0')}:${_dailySummaryTime.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectTime(context, 'daily'),
              ),
              ListTile(
                leading: const Icon(Icons.nightlight_round),
                title: const Text('Akşam Özeti'),
                subtitle: Text('${_eveningSummaryTime.hour.toString().padLeft(2, '0')}:${_eveningSummaryTime.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectTime(context, 'evening'),
              ),
              ListTile(
                leading: const Icon(Icons.local_fire_department),
                title: const Text('Seri Hatırlatıcısı'),
                subtitle: Text('${_streakReminderTime.hour.toString().padLeft(2, '0')}:${_streakReminderTime.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectTime(context, 'streak'),
              ),
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Süre Uyarısı'),
                subtitle: Text('$_reminderMinutes dakika önce'),
                trailing: DropdownButton<int>(
                  value: _reminderMinutes,
                  items: [15, 30, 60].map((min) {
                    return DropdownMenuItem(
                      value: min,
                      child: Text('$min dk'),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _reminderMinutes = value;
                      });
                      await NotificationService.setReminderMinutes(value);
                    }
                  },
                ),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Test Butonları',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await NotificationService.showInstantNotification();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Anlık bildirim gönderildi!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.flash_on, size: 16),
                        label: const Text('Hemen', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await NotificationService.scheduleTestNotification();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('15 saniye sonra bildirim!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.timer, size: 16),
                        label: const Text('15 sn', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, String type) async {
    final initialTime = type == 'daily'
        ? _dailySummaryTime
        : type == 'evening'
            ? _eveningSummaryTime
            : _streakReminderTime;

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time != null) {
      setState(() {
        if (type == 'daily') {
          _dailySummaryTime = time;
        } else if (type == 'evening') {
          _eveningSummaryTime = time;
        } else {
          _streakReminderTime = time;
        }
      });

      if (type == 'daily') {
        await NotificationService.scheduleDailySummary(time);
      } else if (type == 'evening') {
        await NotificationService.scheduleEveningSummary(time);
      } else {
        await NotificationService.scheduleStreakReminder(time);
      }
    }
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.get('about', _languageCode),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/MotivAppUse.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.get('app_name', _languageCode),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.get('version', _languageCode),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.get('app_description', _languageCode),
              style: const TextStyle(fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 12),
            _buildAboutItem(Icons.email, AppLocalizations.get('email', _languageCode), 'destek@motivapp.com'),
            _buildAboutItem(Icons.web, AppLocalizations.get('website', _languageCode), 'www.motivapp.com'),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard() {
    return FutureBuilder<bool>(
      future: SubscriptionService.isPremium(),
      builder: (context, snapshot) {
        final isPremium = snapshot.data ?? false;
        
        return Card(
          color: isPremium ? Colors.amber.shade50 : Colors.grey.shade50,
          child: InkWell(
            onTap: isPremium ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PremiumScreen(languageCode: _languageCode),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: isPremium ? Colors.amber.shade700 : Colors.grey.shade600,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium
                              ? (_languageCode == 'tr' ? 'Premium Üye' : 'Premium Member')
                              : (_languageCode == 'tr' ? 'Premium\'a Geç' : 'Go Premium'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isPremium ? Colors.amber.shade700 : Colors.grey.shade800,
                          ),
                        ),
                        if (isPremium)
                          FutureBuilder<DateTime?>(
                            future: SubscriptionService.getPremiumExpiryDate(),
                            builder: (context, dateSnapshot) {
                              if (dateSnapshot.hasData && dateSnapshot.data != null) {
                                final daysLeft = dateSnapshot.data!.difference(DateTime.now()).inDays;
                                return Text(
                                  _languageCode == 'tr'
                                      ? '$daysLeft gün kaldı'
                                      : '$daysLeft days left',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          )
                        else
                          Text(
                            _languageCode == 'tr'
                                ? 'Tüm özelliklerin kilidini aç'
                                : 'Unlock all features',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isPremium)
                    Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: Text(
          AppLocalizations.get('sign_out', _languageCode),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profile = UserProfile(
        id: AuthService.getCurrentUser()!.id,
        email: AuthService.getCurrentUser()!.email!,
        fullName: _fullNameController.text.trim(),
        age: int.tryParse(_ageController.text),
        country: _selectedCountry,
        city: _selectedCity,
      );

      await ProfileService.updateProfile(profile);
      
      setState(() {
        _profile = profile;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('profile_updated', _languageCode)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('error_occurred', _languageCode)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.get('sign_out', _languageCode)),
        content: Text(AppLocalizations.get('sign_out_confirm', _languageCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.get('cancel', _languageCode)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              AppLocalizations.get('sign_out', _languageCode),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.get('error_occurred', _languageCode)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}