import 'package:flutter/material.dart';
import '../models/motivation.dart';
import 'add_motivation_screen.dart';
import 'completed_routines_screen.dart';
import 'motivation_detail_screen.dart';
import 'dashboard_screen.dart';
import 'daily_tasks_screen.dart';
import 'account_screen.dart';
import '../services/language_service.dart';
import '../services/database_service.dart';
import '../services/subscription_service.dart';
import 'premium_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Motivation> motivations = [];
  List<Motivation> completedRoutines = [];
  int _currentIndex = 0;
  String _languageCode = 'tr';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _loadMotivations();
  }

  Future<void> _loadMotivations() async {
    try {
      final loadedMotivations = await DatabaseService.getMotivations();
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
          GestureDetector(
            onTap: () {
              final newLanguage = _languageCode == 'tr' ? 'en' : 'tr';
              _changeLanguage(newLanguage);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _languageCode == 'tr' ? '🇹🇷' : '🇺🇸',
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
            ),
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
      bottomNavigationBar: BottomNavigationBar(
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
              builder: (context) => AddMotivationScreen(languageCode: _languageCode),
            ),
          );
          if (result != null && result is Motivation) {
            await DatabaseService.insertMotivation(result);
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
                        if (motivation.targetMinutes > 0) ...[
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
      await DatabaseService.updateMotivation(completedMotivation);
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
    
    try {
      await DatabaseService.deleteMotivation(motivation.id);
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

  Color _getCategoryColor(MotivationCategory category) {
    switch (category) {
      case MotivationCategory.spiritual:
        return Colors.green.shade600;
      case MotivationCategory.education:
        return Colors.blue.shade600;
      case MotivationCategory.health:
        return Colors.orange.shade600;
      case MotivationCategory.household:
        return Colors.brown.shade600;
      case MotivationCategory.selfCare:
        return Colors.pink.shade600;
      case MotivationCategory.social:
        return Colors.teal.shade600;
      case MotivationCategory.hobby:
        return Colors.indigo.shade600;
      case MotivationCategory.career:
        return Colors.deepOrange.shade600;
      case MotivationCategory.personal:
        return Colors.purple.shade600;
    }
  }

  IconData _getCategoryIcon(MotivationCategory category) {
    switch (category) {
      case MotivationCategory.spiritual:
        return Icons.mosque;
      case MotivationCategory.education:
        return Icons.school;
      case MotivationCategory.health:
        return Icons.health_and_safety;
      case MotivationCategory.household:
        return Icons.home;
      case MotivationCategory.selfCare:
        return Icons.spa;
      case MotivationCategory.social:
        return Icons.people;
      case MotivationCategory.hobby:
        return Icons.palette;
      case MotivationCategory.career:
        return Icons.work;
      case MotivationCategory.personal:
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
    await DatabaseService.translateExistingMotivations(languageCode);
    await _loadMotivations();
  }

  Map<MotivationCategory, List<Motivation>> _groupMotivationsByCategory() {
    final Map<MotivationCategory, List<Motivation>> grouped = {};
    
    for (final motivation in motivations) {
      if (!grouped.containsKey(motivation.category)) {
        grouped[motivation.category] = [];
      }
      grouped[motivation.category]!.add(motivation);
    }
    
    return grouped;
  }
  
  String _getCategoryName(MotivationCategory category) {
    switch (category) {
      case MotivationCategory.spiritual:
        return AppLocalizations.get('spiritual', _languageCode);
      case MotivationCategory.education:
        return AppLocalizations.get('education', _languageCode);
      case MotivationCategory.health:
        return AppLocalizations.get('health', _languageCode);
      case MotivationCategory.household:
        return AppLocalizations.get('household', _languageCode);
      case MotivationCategory.selfCare:
        return AppLocalizations.get('self_care', _languageCode);
      case MotivationCategory.social:
        return AppLocalizations.get('social', _languageCode);
      case MotivationCategory.hobby:
        return AppLocalizations.get('hobby', _languageCode);
      case MotivationCategory.career:
        return AppLocalizations.get('career', _languageCode);
      case MotivationCategory.personal:
        return AppLocalizations.get('personal', _languageCode);
    }
  }

  String _getFrequencyText(MotivationFrequency frequency) {
    switch (frequency) {
      case MotivationFrequency.daily:
        return AppLocalizations.get('daily', _languageCode);
      case MotivationFrequency.weekly:
        return AppLocalizations.get('weekly', _languageCode);
      case MotivationFrequency.monthly:
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