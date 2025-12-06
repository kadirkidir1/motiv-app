import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/daily_note.dart';
import '../services/database_service.dart';
import '../services/language_service.dart';
import '../services/tracking_service.dart';

class DailyRecordScreen extends StatefulWidget {
  final Routine motivation;
  final String? languageCode;

  const DailyRecordScreen({
    super.key,
    required this.motivation,
    this.languageCode,
  });

  @override
  State<DailyRecordScreen> createState() => _DailyRecordScreenState();
}

class _DailyRecordScreenState extends State<DailyRecordScreen> {
  final _minutesController = TextEditingController();
  final _noteController = TextEditingController();
  bool completed = false;
  int selectedMood = 3;
  String _languageCode = 'tr';

  @override
  void initState() {
    super.initState();
    _languageCode = widget.languageCode ?? 'tr';
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = await LanguageService.getLanguage();
    if (mounted) {
      setState(() {
        _languageCode = language;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.get('daily_record', _languageCode),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMotivationCard(),
            const SizedBox(height: 24),
            _buildCompletionStatus(),
            const SizedBox(height: 20),
            if (completed) _buildTimeInput(),
            const SizedBox(height: 20),
            _buildMoodSelector(),
            const SizedBox(height: 20),
            _buildNoteInput(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getCategoryColor(widget.motivation.category),
              radius: 24,
              child: Icon(
                _getCategoryIcon(widget.motivation.category),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.motivation.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.motivation.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(widget.motivation.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${AppLocalizations.get('target', _languageCode)}: ${widget.motivation.targetMinutes} ${AppLocalizations.get('minutes', _languageCode)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCategoryColor(widget.motivation.category),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.get('did_you_complete', _languageCode),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        completed = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: completed ? Colors.green : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: completed ? Colors.green : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: completed ? Colors.white : Colors.grey.shade600,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.get('yes_did_it', _languageCode),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: completed ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        completed = false;
                        _minutesController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: !completed ? Colors.red : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !completed ? Colors.red : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cancel,
                            color: !completed ? Colors.white : Colors.grey.shade600,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.get('no_could_not', _languageCode),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: !completed ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.get('how_many_minutes', _languageCode),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.motivation.targetMinutes > 0) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _minutesController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.get('minutes', _languageCode),
                  border: const OutlineInputBorder(),
                  suffixText: AppLocalizations.get('minutes', _languageCode),
                  hintText: '${AppLocalizations.get('example', _languageCode)}: ${widget.motivation.targetMinutes}',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.get('how_do_you_feel_today', _languageCode),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final mood = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
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
                      border: Border.all(
                        color: selectedMood == mood
                            ? _getMoodColor(mood)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getMoodEmoji(mood),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getMoodText(mood),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: selectedMood == mood
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.get('notes_optional', _languageCode),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: AppLocalizations.get('how_was_today', _languageCode),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveRecord,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getCategoryColor(widget.motivation.category),
        ),
        child: Text(
          AppLocalizations.get('complete_record', _languageCode),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _saveRecord() async {
    final minutesSpent = int.tryParse(_minutesController.text) ?? 0;
    
    final dailyNote = DailyNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      routineId: widget.motivation.id,
      date: DateTime.now(),
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      mood: selectedMood,
      tags: [],
    );
    
    try {
      if (_noteController.text.trim().isNotEmpty) {
        await DatabaseService.insertDailyNote(dailyNote);
      }
      if (completed) {
        await TrackingService.completeRoutine(
          routineId: widget.motivation.id,
          date: DateTime.now(),
          minutesSpent: minutesSpent,
          notes: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              completed 
                  ? '${widget.motivation.title} ${AppLocalizations.get('daily_record_completed', _languageCode)}'
                  : AppLocalizations.get('record_saved_try_tomorrow', _languageCode),
            ),
            backgroundColor: completed ? Colors.green : Colors.orange,
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

  Color _getMoodColor(int mood) {
    switch (mood) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
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

  String _getMoodText(int mood) {
    switch (mood) {
      case 1:
        return AppLocalizations.get('mood_bad', _languageCode);
      case 2:
        return AppLocalizations.get('mood_difficult', _languageCode);
      case 3:
        return AppLocalizations.get('mood_normal', _languageCode);
      case 4:
        return AppLocalizations.get('mood_good', _languageCode);
      case 5:
        return AppLocalizations.get('mood_great', _languageCode);
      default:
        return AppLocalizations.get('mood_normal', _languageCode);
    }
  }
}