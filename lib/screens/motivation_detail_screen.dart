import 'package:flutter/material.dart';
import '../models/motivation.dart';
import '../models/daily_note.dart';
import '../services/language_service.dart';
import '../services/database_service.dart';

class MotivationDetailScreen extends StatefulWidget {
  final Motivation motivation;

  const MotivationDetailScreen({
    super.key,
    required this.motivation,
  });

  @override
  State<MotivationDetailScreen> createState() => _MotivationDetailScreenState();
}

class _MotivationDetailScreenState extends State<MotivationDetailScreen> {
  List<MotivationProgress> progressList = [];
  List<DailyNote> dailyNotes = [];
  String selectedPeriod = '';
  String _languageCode = 'tr';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _loadRealData();
  }
  
  _loadLanguage() async {
    final language = await LanguageService.getLanguage();
    setState(() {
      _languageCode = language;
      selectedPeriod = AppLocalizations.get('daily', language);
    });
  }

  Future<void> _loadRealData() async {
    try {
      // Daily notes'ları database'den yükle
      final notes = await DatabaseService.getDailyNotes(widget.motivation.id);
      
      // Progress verilerini daily notes'lardan oluştur
      final now = DateTime.now();
      final Map<String, DailyNote> notesByDate = {};
      
      for (var note in notes) {
        final dateKey = '${note.date.year}-${note.date.month}-${note.date.day}';
        notesByDate[dateKey] = note;
      }
      
      // Son 30 günün progress verilerini oluştur
      final List<MotivationProgress> newProgressList = [];
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month}-${date.day}';
        final note = notesByDate[dateKey];
        
        newProgressList.add(MotivationProgress(
          motivationId: widget.motivation.id,
          date: date,
          completed: note != null,
          minutesSpent: note != null ? _getMinutesFromNote(note) : 0,
        ));
      }
      
      setState(() {
        dailyNotes = notes;
        progressList = newProgressList;
      });
    } catch (e) {
      // Hata durumunda boş verilerle devam et
      setState(() {
        dailyNotes = [];
        progressList = _generateEmptyProgress();
      });
    }
  }
  
  int _getMinutesFromNote(DailyNote note) {
    // Daily note'dan dakika bilgisini çıkar
    // Şimdilik hedef dakikayı kullan, ileride note'a minutesSpent eklenebilir
    return widget.motivation.targetMinutes;
  }
  
  List<MotivationProgress> _generateEmptyProgress() {
    final now = DateTime.now();
    return List.generate(30, (index) {
      final date = now.subtract(Duration(days: 29 - index));
      return MotivationProgress(
        motivationId: widget.motivation.id,
        date: date,
        completed: false,
        minutesSpent: 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysSinceCreated = DateTime.now().difference(widget.motivation.createdAt).inDays;
    final completedDays = progressList.where((p) => p.completed).length;
    final streakDays = _calculateCurrentStreak();
    final completionRate = progressList.isEmpty ? 0 : (completedDays / progressList.length * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.motivation.title),
        backgroundColor: _getCategoryColor(widget.motivation.category),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: _addDailyNote,
          ),
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: _markTodayComplete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatsCards(daysSinceCreated, completedDays, streakDays, completionRate),
            _buildPeriodSelector(),
            _buildProgressChart(),
            _buildCalendarView(),
            _buildDailyNotes(),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(int daysSinceCreated, int completedDays, int streakDays, int completionRate) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.get('total_days', _languageCode),
                  '$daysSinceCreated',
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.get('completed_days', _languageCode),
                  '$completedDays',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.get('current_streak', _languageCode),
                  '$streakDays ${AppLocalizations.get('days', _languageCode)}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.get('success_rate', _languageCode),
                  '%$completionRate',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '${AppLocalizations.get('view_details', _languageCode)}:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  AppLocalizations.get('daily', _languageCode),
                  AppLocalizations.get('weekly', _languageCode),
                  AppLocalizations.get('monthly', _languageCode)
                ].map((period) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(period),
                      selected: selectedPeriod == period,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedPeriod = period;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppLocalizations.get('progress_chart', _languageCode)} ($selectedPeriod)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildSimpleChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.get('last_30_days', _languageCode),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: progressList.length.clamp(0, 30),
                itemBuilder: (context, index) {
                  if (index >= progressList.length) return const SizedBox();
                  final progress = progressList[index];
                  return GestureDetector(
                    onTap: () => _showDayDetails(progress),
                    child: Container(
                      decoration: BoxDecoration(
                        color: progress.completed ? Colors.green : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${progress.date.day}',
                          style: TextStyle(
                            fontSize: 12,
                            color: progress.completed ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.get('daily_notes', _languageCode),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addDailyNote,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppLocalizations.get('add_note', _languageCode)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              dailyNotes.isEmpty
                  ? Text(
                      AppLocalizations.get('no_notes_yet', _languageCode),
                      style: const TextStyle(color: Colors.grey),
                    )
                  : Column(
                      children: dailyNotes.take(3).map((note) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getMoodColor(note.mood),
                              child: Text(
                                _getMoodEmoji(note.mood),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            title: Text(
                              note.note,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              _formatDate(note.date),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentProgress = progressList.reversed.take(7).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.get('recent_activities', _languageCode),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...recentProgress.map((progress) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: progress.completed ? Colors.green : Colors.grey,
                    radius: 16,
                    child: Icon(
                      progress.completed ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    _formatDate(progress.date),
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    progress.completed 
                        ? '${progress.minutesSpent} ${AppLocalizations.get('minutes', _languageCode)}'
                        : AppLocalizations.get('not_completed', _languageCode),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: progress.completed
                      ? Icon(Icons.psychology, color: Colors.green.shade600, size: 20)
                      : null,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateCurrentStreak() {
    int streak = 0;
    for (int i = progressList.length - 1; i >= 0; i--) {
      if (progressList[i].completed) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  void _addDailyNote() {
    final noteController = TextEditingController();
    int selectedMood = 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.get('add_daily_note', _languageCode)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.get('how_was_today', _languageCode),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.get('how_do_you_feel', _languageCode)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final mood = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedMood = mood;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedMood == mood
                            ? _getMoodColor(mood)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getMoodEmoji(mood),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.get('cancel', _languageCode)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (noteController.text.isNotEmpty) {
                  final note = DailyNote(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    motivationId: widget.motivation.id,
                    date: DateTime.now(),
                    note: noteController.text,
                    mood: selectedMood,
                  );
                  
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final noteSavedText = AppLocalizations.get('note_saved', _languageCode);
                  final errorText = AppLocalizations.get('error_occurred', _languageCode);
                  
                  try {
                    await DatabaseService.insertDailyNote(note, true, widget.motivation.targetMinutes);
                    setState(() {
                      dailyNotes.insert(0, note);
                    });
                    _loadRealData(); // Verileri yenile
                    
                    navigator.pop();
                    if (mounted) {
                      messenger.showSnackBar(SnackBar(content: Text(noteSavedText)));
                    }
                  } catch (e) {
                    navigator.pop();
                    if (mounted) {
                      messenger.showSnackBar(SnackBar(content: Text(errorText)));
                    }
                  }
                }
              },
              child: Text(AppLocalizations.get('save', _languageCode)),
            ),
          ],
        ),
      ),
    );
  }

  void _markTodayComplete() {
    final minutesController = TextEditingController(
      text: widget.motivation.targetMinutes.toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.get('complete_today_title', _languageCode)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.get('did_you_complete', _languageCode)),
            const SizedBox(height: 16),
            TextField(
              controller: minutesController,
              decoration: InputDecoration(
                labelText: AppLocalizations.get('how_many_minutes', _languageCode),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.get('cancel', _languageCode)),
          ),
          ElevatedButton(
            onPressed: () async {
              final minutes = int.tryParse(minutesController.text) ?? widget.motivation.targetMinutes;
              
              final note = DailyNote(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                motivationId: widget.motivation.id,
                date: DateTime.now(),
                note: 'Tamamlandı',
                mood: 4, // İyi ruh hali
              );
              
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final markedCompleteText = AppLocalizations.get('marked_complete', _languageCode);
              final errorText = AppLocalizations.get('error_occurred', _languageCode);
              
              try {
                await DatabaseService.insertDailyNote(note, true, minutes);
                _loadRealData(); // Verileri yenile
                
                navigator.pop();
                if (mounted) {
                  messenger.showSnackBar(SnackBar(content: Text(markedCompleteText)));
                }
              } catch (e) {
                navigator.pop();
                if (mounted) {
                  messenger.showSnackBar(SnackBar(content: Text(errorText)));
                }
              }
            },
            child: Text(AppLocalizations.get('complete', _languageCode)),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(int mood) {
    switch (mood) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '🙁';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
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

  Widget _buildSimpleChart() {
    final last7Days = progressList.reversed.take(7).toList().reversed.toList();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: last7Days.map((progress) {
        final height = progress.completed ? (progress.minutesSpent / 60 * 80) + 20 : 10.0;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: height.clamp(10, 100),
                  decoration: BoxDecoration(
                    color: progress.completed ? Colors.blue.shade400 : Colors.grey.shade300,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${progress.date.day}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  void _showDayDetails(MotivationProgress progress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${progress.date.day}/${progress.date.month}/${progress.date.year}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  progress.completed ? Icons.check_circle : Icons.cancel,
                  color: progress.completed ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  progress.completed ? AppLocalizations.get('completed_status', _languageCode) : AppLocalizations.get('not_completed_status', _languageCode),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: progress.completed ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            if (progress.completed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.timer, size: 16),
                  const SizedBox(width: 8),
                  Text('${progress.minutesSpent} ${AppLocalizations.get('minutes', _languageCode)}'),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(_formatDate(progress.date)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.get('ok', _languageCode)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return AppLocalizations.get('today', _languageCode);
    if (difference == 1) return AppLocalizations.get('yesterday', _languageCode);
    if (difference < 7) return '$difference ${AppLocalizations.get('days_ago', _languageCode)}';
    
    return '${date.day}/${date.month}/${date.year}';
  }
}