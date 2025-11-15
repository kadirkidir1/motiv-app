import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';
import '../services/subscription_service.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'login_screen.dart';
import 'premium_screen.dart';
import 'splash_screen.dart';

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
  String _languageCode = 'tr';
  bool _isLoading = false;
  bool _isGuest = false;
  
  bool _notificationsEnabled = true;
  TimeOfDay _dailySummaryTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _eveningSummaryTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _streakReminderTime = const TimeOfDay(hour: 21, minute: 0);
  int _reminderMinutes = 30;

  @override
  void initState() {
    super.initState();
    _languageCode = widget.languageCode;
    _checkGuestMode();
    _loadProfile();
    _loadNotificationSettings();
  }

  Future<void> _checkGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGuest = prefs.getBool('is_guest') ?? false;
    });
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
      await ProfileService.getProfile();
      // Profile loaded successfully
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
                  const SizedBox(height: 24),
                  _buildRewardedAdCard(),
                  const SizedBox(height: 24),
                  _buildLanguageSettings(),
                  const SizedBox(height: 24),
                  _buildThemeSettings(),
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
              backgroundColor: _isGuest ? Colors.grey.shade100 : Colors.blue.shade100,
              child: Icon(
                _isGuest ? Icons.person_outline : Icons.person,
                size: 50,
                color: _isGuest ? Colors.grey.shade600 : Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isGuest 
                  ? (_languageCode == 'tr' ? 'Misafir Kullanıcı' : 'Guest User')
                  : (user?.email ?? ''),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isGuest) ...[
              const SizedBox(height: 8),
              Text(
                _languageCode == 'tr' 
                    ? 'Verileriniz sadece bu cihazda saklanıyor'
                    : 'Your data is stored only on this device',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createAccount,
                icon: const Icon(Icons.person_add),
                label: Text(_languageCode == 'tr' ? 'Hesap Oluştur' : 'Create Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildRewardedAdCard() {
    return Card(
      color: Colors.green.shade50,
      child: InkWell(
        onTap: _showRewardedAd,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.play_circle_filled, color: Colors.green.shade600, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _languageCode == 'tr' ? 'Destek İçin Video İzle!' :
                      _languageCode == 'de' ? 'Video ansehen für Support!' :
                      _languageCode == 'fr' ? 'Regardez la vidéo pour le support!' :
                      _languageCode == 'it' ? 'Guarda il video per il supporto!' : 'Watch Video for Support!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _languageCode == 'tr' ? 'Bize destek olmak için kısa bir video izle' :
                      _languageCode == 'de' ? 'Sehen Sie sich ein kurzes Video an, um uns zu unterstützen' :
                      _languageCode == 'fr' ? 'Regardez une courte vidéo pour nous soutenir' :
                      _languageCode == 'it' ? 'Guarda un breve video per supportarci' : 'Watch a short video to support us',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.green.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRewardedAd() async {
    final rewardedAd = await AdService.loadRewardedAd();
    
    if (rewardedAd == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_languageCode == 'tr' ? 'Reklam yüklenemedi' : 'Ad failed to load'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
      },
    );

    await rewardedAd.show(
      onUserEarnedReward: (ad, reward) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _languageCode == 'tr' ? 'Teşekkürler! Desteğiniz için sağ olun ❤️' :
                _languageCode == 'de' ? 'Danke! Vielen Dank für Ihre Unterstützung ❤️' :
                _languageCode == 'fr' ? 'Merci! Merci pour votre soutien ❤️' :
                _languageCode == 'it' ? 'Grazie! Grazie per il tuo supporto ❤️' : 'Thank you! Thanks for your support ❤️'
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  Widget _buildLanguageSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  _languageCode == 'tr' ? 'Dil' : 
                  _languageCode == 'de' ? 'Sprache' :
                  _languageCode == 'fr' ? 'Langue' :
                  _languageCode == 'it' ? 'Lingua' : 'Language',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_languageCode == 'tr' ? 'Uygulama Dili' : 
                          _languageCode == 'de' ? 'App-Sprache' :
                          _languageCode == 'fr' ? 'Langue de l\'application' :
                          _languageCode == 'it' ? 'Lingua dell\'app' : 'App Language'),
              trailing: DropdownButton<String>(
                value: _languageCode,
                items: const [
                  DropdownMenuItem(value: 'tr', child: Text('🇹🇷 Türkçe')),
                  DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
                  DropdownMenuItem(value: 'de', child: Text('🇩🇪 Deutsch')),
                  DropdownMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
                  DropdownMenuItem(value: 'it', child: Text('🇮🇹 Italiano')),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    await LanguageService.setLanguage(value);
                    if (mounted) {
                      // Restart the app to apply language change
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const SplashScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSettings() {
    final themeService = Provider.of<ThemeService>(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  _languageCode == 'tr' ? 'Tema' : 'Theme',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(_languageCode == 'tr' ? 'Karanlık Mod' : 'Dark Mode'),
              subtitle: Text(_languageCode == 'tr' ? 'Gözlerinizi koruyun' : 'Protect your eyes'),
              value: themeService.isDarkMode,
              onChanged: (value) => themeService.toggleTheme(),
              secondary: Icon(
                themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Colors.blue.shade600,
              ),
            ),
          ],
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
                Text(
                  _languageCode == 'tr' ? 'Bildirim Ayarları' : 'Notification Settings',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _languageCode == 'tr'
                          ? 'Bildirimler uygulama açıldığında kontrol edilir'
                          : 'Notifications checked when app opens',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(_languageCode == 'tr' ? 'Bildirimleri Aç' : 'Enable Notifications'),
              subtitle: Text(_languageCode == 'tr' ? 'Tüm bildirimleri etkinleştir/kapat' : 'Enable/disable all notifications'),
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
                title: Text(_languageCode == 'tr' ? 'Günlük Özet Saati' : 'Daily Summary Time'),
                subtitle: Text('${_dailySummaryTime.hour.toString().padLeft(2, '0')}:${_dailySummaryTime.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectTime(context, 'daily'),
              ),
              ListTile(
                leading: const Icon(Icons.nightlight_round),
                title: Text(_languageCode == 'tr' ? 'Akşam Özeti' : 'Evening Summary'),
                subtitle: Text('${_eveningSummaryTime.hour.toString().padLeft(2, '0')}:${_eveningSummaryTime.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectTime(context, 'evening'),
              ),
              ListTile(
                leading: const Icon(Icons.local_fire_department),
                title: Text(_languageCode == 'tr' ? 'Seri Hatırlatıcısı' : 'Streak Reminder'),
                subtitle: Text('${_streakReminderTime.hour.toString().padLeft(2, '0')}:${_streakReminderTime.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectTime(context, 'streak'),
              ),
              ListTile(
                leading: const Icon(Icons.timer),
                title: Text(_languageCode == 'tr' ? 'Süre Uyarısı' : 'Time Warning'),
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
            _buildAboutItem(Icons.email, AppLocalizations.get('email', _languageCode), 'motivapp2025@gmail.com'),
          ],
        ),
      ),
    );
  }

  Future<void> _createAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_guest');
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildPremiumCard() {
    if (_isGuest) {
      return Card(
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.grey.shade400, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _languageCode == 'tr'
                      ? 'Premium özellikleri kullanmak için hesap oluşturun'
                      : 'Create an account to use premium features',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
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
    if (_isGuest) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: _clearGuestData,
          icon: const Icon(Icons.delete_sweep, color: Colors.orange),
          label: Text(
            _languageCode == 'tr' ? 'Verileri Temizle' : 'Clear Data',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.orange),
          ),
        ),
      );
    }
    
    return Column(
      children: [
        // Aboneliği Yönet
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _manageSubscription,
            icon: const Icon(Icons.card_membership, color: Colors.blue),
            label: Text(
              _languageCode == 'tr' ? 'Aboneliği Yönet' : 'Manage Subscription',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Hesabı Sil
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete_forever, color: Colors.orange),
            label: Text(
              _languageCode == 'tr' ? 'Hesabı Sil' : 'Delete Account',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Çıkış Yap
        SizedBox(
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
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _clearGuestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_languageCode == 'tr' ? 'Verileri Temizle' : 'Clear Data'),
        content: Text(
          _languageCode == 'tr'
              ? 'Tüm verileriniz silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?'
              : 'All your data will be deleted. This action cannot be undone. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_languageCode == 'tr' ? 'İptal' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              _languageCode == 'tr' ? 'Sil' : 'Delete',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Clear local database
        await DatabaseService.clearAllRoutines();
        
        // Clear guest flag
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('is_guest');
        
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
              content: Text(_languageCode == 'tr' ? 'Bir hata oluştu' : 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }



  Future<void> _manageSubscription() async {
    final isPremium = await SubscriptionService.isPremium();
    
    if (!isPremium) {
      // Premium değilse premium ekranına yönlendir
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PremiumScreen(languageCode: _languageCode),
          ),
        );
      }
      return;
    }
    
    // Premium ise Google Play'e yönlendir
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_languageCode == 'tr' ? 'Aboneliği Yönet' : 'Manage Subscription'),
        content: Text(
          _languageCode == 'tr'
              ? 'Aboneliğinizi yönetmek için Google Play Store > Hesap > Ödemeler ve abonelikler bölümüne gidin.'
              : 'To manage your subscription, go to Google Play Store > Account > Payments & subscriptions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_languageCode == 'tr' ? 'Tamam' : 'OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_languageCode == 'tr' ? 'Hesabı Sil' : 'Delete Account'),
        content: Text(
          _languageCode == 'tr'
              ? 'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz ve tüm verileriniz silinecektir.'
              : 'Are you sure you want to delete your account? This action cannot be undone and all your data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.get('cancel', _languageCode)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              _languageCode == 'tr' ? 'Sil' : 'Delete',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = AuthService.getCurrentUser();
        if (user != null) {
          // Supabase'de hesabı deaktif et (silme yerine)
          await Supabase.instance.client
              .from('user_profiles')
              .update({'is_active': false, 'deleted_at': DateTime.now().toIso8601String()})
              .eq('user_id', user.id);
          
          // Çıkış yap
          await AuthService.signOut();
          
          if (mounted) {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_languageCode == 'tr' ? 'Hesabınız silindi' : 'Your account has been deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
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