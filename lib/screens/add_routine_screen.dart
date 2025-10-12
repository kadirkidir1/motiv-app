import 'package:flutter/material.dart';
import '../models/routine.dart';
import 'routine_detail_setup_screen.dart';
import '../services/language_service.dart';
import '../services/predefined_routines.dart';
import '../services/notification_service.dart';
import 'celebration_screen.dart';

class AddRoutineScreen extends StatefulWidget {
  final String languageCode;
  
  const AddRoutineScreen({super.key, required this.languageCode});

  @override
  State<AddRoutineScreen> createState() => _AddRoutineScreenState();
}

class _AddRoutineScreenState extends State<AddRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetMinutesController = TextEditingController();

  RoutineCategory _selectedCategory = RoutineCategory.personal;
  RoutineFrequency _selectedFrequency = RoutineFrequency.daily;
  bool _hasAlarm = false;
  TimeOfDay? _alarmTime;
  bool _isTimeBased = true;

  RoutineCategory? _selectedCategoryFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('add_motivation', widget.languageCode)),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.get('predefined_routines', widget.languageCode),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${PredefinedRoutines.getTotalRoutinesCount()} ${PredefinedRoutines.getTotalRoutinesCount() == 1 ? AppLocalizations.get('motivation', widget.languageCode) : AppLocalizations.get('motivations', widget.languageCode)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCategoryTabs(),
            const SizedBox(height: 16),
            _buildPredefinedRoutines(),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.get('custom_motivation', widget.languageCode),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCustomMotivationForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    const categories = RoutineCategory.values;
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1, // +1 for "All" tab
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(AppLocalizations.get('all', widget.languageCode)),
                selected: _selectedCategoryFilter == null,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategoryFilter = null;
                  });
                },
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue.shade600,
              ),
            );
          }
          
          final category = categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(PredefinedRoutines.getCategoryName(category, widget.languageCode)),
              selected: _selectedCategoryFilter == category,
              onSelected: (selected) {
                setState(() {
                  _selectedCategoryFilter = selected ? category : null;
                });
              },
              selectedColor: _getCategoryColor(category).withValues(alpha: 0.2),
              checkmarkColor: _getCategoryColor(category),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPredefinedRoutines() {
    final allMotivations = PredefinedRoutines.getRoutines(widget.languageCode);
    final filteredMotivations = _selectedCategoryFilter == null
        ? allMotivations
        : allMotivations.where((m) => m['category'] == _selectedCategoryFilter).toList();

    if (filteredMotivations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            AppLocalizations.get('no_motivations_found', widget.languageCode),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filteredMotivations.length,
      itemBuilder: (context, index) {
        final motivation = filteredMotivations[index];
        return Card(
          child: InkWell(
            onTap: () => _selectPredefinedMotivation(motivation),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    motivation['icon'],
                    size: 32,
                    color: _getCategoryColor(motivation['category']),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    motivation['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomMotivationForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: AppLocalizations.get('motivation_title', widget.languageCode),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.get('title_required', widget.languageCode);
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: AppLocalizations.get('description', widget.languageCode),
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<RoutineCategory>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              labelText: AppLocalizations.get('category', widget.languageCode),
              border: const OutlineInputBorder(),
            ),
            items: RoutineCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(PredefinedRoutines.getCategoryName(category, widget.languageCode)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<RoutineFrequency>(
            initialValue: _selectedFrequency,
            decoration: InputDecoration(
              labelText: AppLocalizations.get('frequency', widget.languageCode),
              border: const OutlineInputBorder(),
            ),
            items: RoutineFrequency.values.map((frequency) {
              return DropdownMenuItem(
                value: frequency,
                child: Text(_getFrequencyName(frequency)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedFrequency = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(widget.languageCode == 'tr' ? 'Zamanlı Motivasyon' : 'Time-Based Routine'),
            subtitle: Text(widget.languageCode == 'tr' ? 'Kapalıysa sadece tamamlandı/tamamlanmadı sorar' : 'If off, only asks completed/not completed'),
            value: _isTimeBased,
            onChanged: (value) {
              setState(() {
                _isTimeBased = value;
                if (!value) _targetMinutesController.text = '0';
              });
            },
          ),
          const SizedBox(height: 16),
          if (_isTimeBased)
            TextFormField(
              controller: _targetMinutesController,
              decoration: InputDecoration(
                labelText: AppLocalizations.get('target_time', widget.languageCode),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          if (_isTimeBased) const SizedBox(height: 16),
          SwitchListTile(
            title: Text(AppLocalizations.get('set_alarm', widget.languageCode)),
            value: _hasAlarm,
            onChanged: (value) {
              setState(() {
                _hasAlarm = value;
                if (!value) _alarmTime = null;
              });
            },
          ),
          if (_hasAlarm) ...[
            ListTile(
              title: Text(
                _alarmTime != null
                    ? '${AppLocalizations.get('alarm_time', widget.languageCode)}: ${_alarmTime!.format(context)}'
                    : AppLocalizations.get('select_alarm_time', widget.languageCode),
              ),
              trailing: const Icon(Icons.access_time),
              onTap: _selectAlarmTime,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveCustomMotivation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
              ),
              child: Text(
                AppLocalizations.get('save_motivation', widget.languageCode),
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
    );
  }

  void _selectPredefinedMotivation(Map<String, dynamic> motivationData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineDetailSetupScreen(
          baseMotivation: motivationData,
          languageCode: widget.languageCode,
        ),
      ),
    );
    if (result != null && result is Routine && mounted) {
      _showCelebration(result);
    }
  }

  void _saveCustomMotivation() async {
    if (_formKey.currentState!.validate()) {
      final motivation = Routine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        frequency: _selectedFrequency,
        hasAlarm: _hasAlarm,
        alarmTime: _alarmTime,
        createdAt: DateTime.now(),
        targetMinutes: _isTimeBased ? (int.tryParse(_targetMinutesController.text) ?? 0) : 0,
        isTimeBased: _isTimeBased,
      );
      
      // Alarm kurulmuşsa bildirim ayarla
      if (_hasAlarm && _alarmTime != null) {
        await NotificationService.scheduleMotivationReminder(
          motivation.id,
          motivation.title,
          _alarmTime!,
          _isTimeBased,
        );
      }
      
      _showCelebration(motivation);
    }
  }

  void _showCelebration(Routine motivation) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CelebrationScreen(
          message: '"${motivation.title}" motivasyonu oluşturuldu!',
          onComplete: () {
            Navigator.pop(context); // Kutlama ekranını kapat
            Navigator.pop(context, motivation); // Ana ekrana dön
          },
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _selectAlarmTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _alarmTime = picked;
      });
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



  String _getFrequencyName(RoutineFrequency frequency) {
    switch (frequency) {
      case RoutineFrequency.daily:
        return AppLocalizations.get('daily', widget.languageCode);
      case RoutineFrequency.weekly:
        return AppLocalizations.get('weekly', widget.languageCode);
      case RoutineFrequency.monthly:
        return AppLocalizations.get('monthly', widget.languageCode);
    }
  }
}