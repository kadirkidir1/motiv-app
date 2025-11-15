import 'package:flutter/material.dart';
import '../models/routine.dart';
import 'add_routine_screen.dart';
import 'completed_routines_screen.dart';
import 'routine_detail_screen.dart';
import 'dashboard_screen.dart';
import 'daily_tasks_screen.dart';
import 'account_screen.dart';
import '../services/language_service.dart';
import '../services/database_service.dart';
import '../services/subscription_service.dart';
import '../services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'premium_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Routine> motivations = [];
  List<Routine> completedRoutines = [];
  int _currentIndex = 0;
  String _languageCode = 'tr';
  BannerAd? _bannerAd;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _loadMotivations();
    _checkPremiumAndLoadAd();
  }

  Future<void> _checkPremiumAndLoadAd() async {
    _isPremium = await SubscriptionService.isPremium();
    if (!_isPremium) {
      _bannerAd = AdService.createBannerAd()..load();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadMotivations() async {
    try {
      final loadedMotivations = await DatabaseService.getRoutines();
      setState(() {
        motivations = loadedMotivations;
      });
    } catch (e) {
      // Hata durumunda boş liste ile devam et
    }
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
      appBar: _currentIndex == 0 ? AppBar(
        title: Text(AppLocalizations.get('dashboard', _languageCode)),
        backgroundColor: Colors.green.shade300,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _languageCode == 'tr' ? '🇹🇷' : 
                  _languageCode == 'en' ? '🇬🇧' :
                  _languageCode == 'de' ? '🇩🇪' :
                  _languageCode == 'fr' ? '🇫🇷' : '🇮🇹',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  _languageCode.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            onSelected: (value) {
              _changeLanguage(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'tr', child: Text('🇹🇷 Türkçe')),
              PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
              PopupMenuItem(value: 'de', child: Text('🇩🇪 Deutsch')),
              PopupMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
              PopupMenuItem(value: 'it', child: Text('🇮🇹 Italiano')),
            ],
          ),
        ],
      ) : _currentIndex == 1 ? AppBar(
        title: Text(AppLocalizations.get('motivations', _languageCode)),
        backgroundColor: Colors.green.shade300,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompletedRoutinesScreen(
                    completedRoutines: completedRoutines,
                  ),
                ),
              );
            },
          ),
        ],
      ) : _currentIndex == 2 ? AppBar(
        title: Text(AppLocalizations.get('daily_tasks', _languageCode)),
        backgroundColor: Colors.green.shade300,
        foregroundColor: Colors.white,
      ) : AppBar(
        title: Text(AppLocalizations.get('account', _languageCode)),
        backgroundColor: Colors.green.shade300,
        foregroundColor: Colors.white,
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_bannerAd != null && !_isPremium)
            SizedBox(
              height: 50,
              child: AdWidget(ad: _bannerAd!),
            ),
          BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: AppLocalizations.get('dashboard', _languageCode),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: AppLocalizations.get('motivations', _languageCode),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.task_alt),
            label: AppLocalizations.get('daily_tasks', _languageCode),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle),
            label: AppLocalizations.get('account', _languageCode),
          ),
        ],
      ),
        ],
      ),
      floatingActionButton: _currentIndex == 1 ? FloatingActionButton(
        heroTag: "add_motivation",
        onPressed: () async {
          final navigator = Navigator.of(context);
          final canAdd = await SubscriptionService.canAddMotivation();
          if (!mounted) return;
          
          if (!canAdd) {
            _showPremiumRequired();
            return;
          }
          
          final result = await navigator.push(
            MaterialPageRoute(
              builder: (context) => AddRoutineScreen(languageCode: _languageCode),
            ),
          );
          if (result != null && result is Routine) {
            await DatabaseService.insertRoutine(result);
            setState(() {
              motivations.add(result);
            });
          }
        },
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.grey.shade400,
                BlendMode.modulate,
              ),
              child: Image.asset(
                'assets/images/MotivAppUse.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.get('no_motivations', _languageCode),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.get('add_first_motivation', _languageCode),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationsList() {
    final groupedMotivations = _groupMotivationsByCategory();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedMotivations.length,
      itemBuilder: (context, index) {
        final category = groupedMotivations.keys.elementAt(index);
        final categoryMotivations = groupedMotivations[category]!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(category),
              child: Icon(
                _getCategoryIcon(category),
                color: Colors.white,
              ),
            ),
            title: Text(
              _getCategoryName(category),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${categoryMotivations.length} ${categoryMotivations.length == 1 ? AppLocalizations.get('motivation', _languageCode) : AppLocalizations.get('motivations', _languageCode)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            children: categoryMotivations.asMap().entries.map((entry) {
              final motivation = entry.value;
              final globalIndex = motivations.indexOf(motivation);
              
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MotivationDetailScreen(
                        motivation: motivation,
                      ),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.only(left: 72, right: 16),
                title: Text(
                  motivation.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(motivation.description),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (motivation.isTimeBased && motivation.targetMinutes > 0) ...[
                          Icon(
                            Icons.timer,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${motivation.targetMinutes} ${AppLocalizations.get('minutes', _languageCode)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getFrequencyText(motivation.frequency),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (motivation.hasAlarm) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.alarm,
                            size: 14,
                            color: Colors.orange.shade600,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          const Icon(Icons.check, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.get('routine_completed', _languageCode)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.get('delete', _languageCode)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'complete') {
                      _moveToCompleted(globalIndex);
                    } else if (value == 'delete') {
                      _deleteMotivation(globalIndex);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _moveToCompleted(int index) async {
    final motivation = motivations[index];
    final completedMotivation = motivation.copyWith(isCompleted: true);
    
    try {
      await DatabaseService.updateRoutine(completedMotivation);
      setState(() {
        motivations.removeAt(index);
        completedRoutines.add(completedMotivation);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.get('motivation_moved_to_completed', _languageCode))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.get('error_occurred', _languageCode))),
        );
      }
    }
  }

  void _deleteMotivation(int index) async {
    final motivation = motivations[index];
    final isTurkish = _languageCode == 'tr';
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTurkish ? 'Rutini Sil' : 'Delete Routine'),
        content: Text(
          isTurkish
              ? 'Bir rutini sildiğinizde, geriye dönük not ve zaman kayıtlarını takvimden de silmek ister misiniz?'
              : 'When you delete a routine, do you also want to delete past notes and time records from the calendar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(isTurkish ? 'İptal' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isTurkish ? 'Hayır, Sadece Rutini Sil' : 'No, Delete Only Routine'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              isTurkish ? 'Evet, Hepsini Sil' : 'Yes, Delete All',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    if (shouldDelete == null) return;
    
    try {
      if (shouldDelete) {
        await DatabaseService.deleteRoutine(motivation.id);
      } else {
        await DatabaseService.deleteRoutineOnly(motivation.id);
      }
      
      setState(() {
        motivations.removeAt(index);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.get('motivation_deleted', _languageCode))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.get('error_occurred', _languageCode))),
        );
      }
    }
  }

  Color _getCategoryColor(RoutineCategory category) {
    switch (category) {
      case RoutineCategory.spiritual:
        return Colors.green.shade600;
      case RoutineCategory.education:
        return Colors.blue.shade600;
      case RoutineCategory.health:
        return Colors.orange.shade600;
      case RoutineCategory.household:
        return Colors.brown.shade600;
      case RoutineCategory.selfCare:
        return Colors.pink.shade600;
      case RoutineCategory.social:
        return Colors.teal.shade600;
      case RoutineCategory.hobby:
        return Colors.indigo.shade600;
      case RoutineCategory.career:
        return Colors.deepOrange.shade600;
      case RoutineCategory.personal:
        return Colors.purple.shade600;
    }
  }

  IconData _getCategoryIcon(RoutineCategory category) {
    switch (category) {
      case RoutineCategory.spiritual:
        return Icons.mosque;
      case RoutineCategory.education:
        return Icons.school;
      case RoutineCategory.health:
        return Icons.health_and_safety;
      case RoutineCategory.household:
        return Icons.home;
      case RoutineCategory.selfCare:
        return Icons.spa;
      case RoutineCategory.social:
        return Icons.people;
      case RoutineCategory.hobby:
        return Icons.palette;
      case RoutineCategory.career:
        return Icons.work;
      case RoutineCategory.personal:
        return Icons.person;
    }
  }

  Widget _getSelectedPage() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(motivations: motivations, languageCode: _languageCode);
      case 1:
        return motivations.isEmpty ? _buildEmptyState() : _buildMotivationsList();
      case 2:
        return DailyTasksScreen(languageCode: _languageCode);
      case 3:
        return AccountScreen(languageCode: _languageCode);
      default:
        return DashboardScreen(motivations: motivations, languageCode: _languageCode);
    }
  }

  void _changeLanguage(String languageCode) async {
    await LanguageService.setLanguage(languageCode);
    setState(() {
      _languageCode = languageCode;
    });
    // Translate existing motivations and reload
    await DatabaseService.translateExistingRoutines(languageCode);
    await _loadMotivations();
  }

  Map<RoutineCategory, List<Routine>> _groupMotivationsByCategory() {
    final Map<RoutineCategory, List<Routine>> grouped = {};
    
    for (final motivation in motivations) {
      if (!grouped.containsKey(motivation.category)) {
        grouped[motivation.category] = [];
      }
      grouped[motivation.category]!.add(motivation);
    }
    
    return grouped;
  }
  
  String _getCategoryName(RoutineCategory category) {
    switch (category) {
      case RoutineCategory.spiritual:
        return AppLocalizations.get('spiritual', _languageCode);
      case RoutineCategory.education:
        return AppLocalizations.get('education', _languageCode);
      case RoutineCategory.health:
        return AppLocalizations.get('health', _languageCode);
      case RoutineCategory.household:
        return AppLocalizations.get('household', _languageCode);
      case RoutineCategory.selfCare:
        return AppLocalizations.get('self_care', _languageCode);
      case RoutineCategory.social:
        return AppLocalizations.get('social', _languageCode);
      case RoutineCategory.hobby:
        return AppLocalizations.get('hobby', _languageCode);
      case RoutineCategory.career:
        return AppLocalizations.get('career', _languageCode);
      case RoutineCategory.personal:
        return AppLocalizations.get('personal', _languageCode);
    }
  }

  String _getFrequencyText(RoutineFrequency frequency) {
    switch (frequency) {
      case RoutineFrequency.daily:
        return AppLocalizations.get('daily', _languageCode);
      case RoutineFrequency.weekly:
        return AppLocalizations.get('weekly', _languageCode);
      case RoutineFrequency.monthly:
        return AppLocalizations.get('monthly', _languageCode);
    }
  }

  void _showPremiumRequired() {
    final isTurkish = _languageCode == 'tr';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            Text(isTurkish ? 'Premium Gerekli' : 'Premium Required'),
          ],
        ),
        content: Text(
          isTurkish
              ? 'Ücretsiz hesapta en fazla 3 motivasyon ekleyebilirsiniz. Sınırsız motivasyon için Premium\'a geçin!'
              : 'Free accounts can add up to 3 motivations. Upgrade to Premium for unlimited motivations!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTurkish ? 'İptal' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PremiumScreen(languageCode: _languageCode),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
            ),
            child: Text(
              isTurkish ? 'Premium\'a Geç' : 'Go Premium',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}