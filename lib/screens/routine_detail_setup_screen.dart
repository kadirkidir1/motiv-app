import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/language_service.dart';

class RoutineDetailSetupScreen extends StatefulWidget {
  final Map<String, dynamic> baseMotivation;
  final String languageCode;

  const RoutineDetailSetupScreen({
    super.key,
    required this.baseMotivation,
    this.languageCode = 'tr',
  });

  @override
  State<RoutineDetailSetupScreen> createState() => _RoutineDetailSetupScreenState();
}

class _RoutineDetailSetupScreenState extends State<RoutineDetailSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetMinutesController = TextEditingController();
  final _notesController = TextEditingController();

  String? selectedSubType;
  List<String> selectedDays = [];
  RoutineFrequency selectedFrequency = RoutineFrequency.daily;
  bool hasAlarm = false;
  TimeOfDay? alarmTime;
  bool _isTimeBased = true;
  String _currentLanguageCode = 'tr';

  final Map<String, List<String>> subTypes = {
    'Spor Yapma': ['Koşu', 'Yüzme', 'Yoga', 'Pilates', 'Ağırlık Antrenmanı', 'Bisiklet', 'Yürüyüş'],
    'İngilizce Çalışma': ['Kelime Öğrenme', 'Gramer Çalışma', 'Konuşma Pratiği', 'Dinleme', 'Okuma', 'Yazma'],
    'Kitap Okuma': ['Roman', 'Kişisel Gelişim', 'Tarih', 'Bilim', 'Felsefe', 'Biyografi'],
    '5 Vakit Namaz': ['Sabah', 'Öğle', 'İkindi', 'Akşam', 'Yatsı'],
    'Kuran Okuma': ['Meal ile Okuma', 'Tecvid Çalışma', 'Ezber Yapma', 'Tefsir Okuma'],
    'Diş Fırçalama': ['Sabah', 'Akşam', 'Öğle Yemeği Sonrası'],
  };

  List<String> get weekDays => _currentLanguageCode == 'en' 
      ? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
      : ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  @override
  void initState() {
    super.initState();
    _targetMinutesController.text = '30';
    _currentLanguageCode = widget.languageCode;
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = await LanguageService.getLanguage();
    if (mounted && language != _currentLanguageCode) {
      setState(() {
        _currentLanguageCode = language;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final motivationTitle = widget.baseMotivation['title'] as String;
    final availableSubTypes = subTypes[motivationTitle] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('$motivationTitle ${AppLocalizations.get('details', _currentLanguageCode)}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMotivationCard(),
              const SizedBox(height: 24),
              _buildSubTypeSelection(availableSubTypes),
              const SizedBox(height: 20),
              _buildFrequencySelection(),
              const SizedBox(height: 20),
              if (selectedFrequency == RoutineFrequency.weekly) _buildDaySelection(),
              _buildTargetTime(),
              const SizedBox(height: 20),
              _buildAlarmSettings(),
              const SizedBox(height: 20),
              _buildNotesSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
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
            Icon(
              widget.baseMotivation['icon'],
              size: 48,
              color: _getCategoryColor(widget.baseMotivation['category']),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.baseMotivation['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.baseMotivation['description'],
                    style: TextStyle(
                      color: Colors.grey.shade600,
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

  Widget _buildSubTypeSelection(List<String> availableSubTypes) {
    if (availableSubTypes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.get('type_selection', _currentLanguageCode),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableSubTypes.map((subType) {
            return ChoiceChip(
              label: Text(subType),
              selected: selectedSubType == subType,
              onSelected: (selected) {
                setState(() {
                  selectedSubType = selected ? subType : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFrequencySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.get('how_often', _currentLanguageCode),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: RoutineFrequency.values.map((frequency) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_getFrequencyName(frequency)),
                  selected: selectedFrequency == frequency,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedFrequency = frequency;
                        if (frequency != RoutineFrequency.weekly) {
                          selectedDays.clear();
                        }
                      });
                    }
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDaySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.get('which_days', _currentLanguageCode),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: weekDays.map((day) {
            return FilterChip(
              label: Text(day),
              selected: selectedDays.contains(day),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedDays.add(day);
                  } else {
                    selectedDays.remove(day);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTargetTime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.get('target_time', _currentLanguageCode),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: Text(_currentLanguageCode == 'tr' ? 'Zamanlamalı' : 'Time-based'),
          subtitle: Text(_currentLanguageCode == 'tr' ? 'Süre hedefi belirle' : 'Set time target'),
          value: _isTimeBased,
          onChanged: (value) {
            setState(() {
              _isTimeBased = value;
              if (!value) {
                _targetMinutesController.text = '0';
              } else if (_targetMinutesController.text == '0') {
                _targetMinutesController.text = '30';
              }
            });
          },
        ),
        if (_isTimeBased) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _targetMinutesController,
            decoration: InputDecoration(
              labelText: AppLocalizations.get('minutes', _currentLanguageCode),
              border: const OutlineInputBorder(),
              suffixText: AppLocalizations.get('minutes', _currentLanguageCode),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_isTimeBased && (value == null || value.isEmpty)) {
                return AppLocalizations.get('target_time_minutes', _currentLanguageCode);
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAlarmSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.get('reminder', _currentLanguageCode),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: Text(AppLocalizations.get('set_alarm', _currentLanguageCode)),
          subtitle: Text(AppLocalizations.get('alarm_desc', _currentLanguageCode)),
          value: hasAlarm,
          onChanged: (value) {
            setState(() {
              hasAlarm = value;
              if (!value) alarmTime = null;
            });
          },
        ),
        if (hasAlarm) ...[
          ListTile(
            title: Text(
              alarmTime != null
                  ? '${AppLocalizations.get('alarm_time', _currentLanguageCode)}: ${alarmTime!.format(context)}'
                  : AppLocalizations.get('select_alarm_time', _currentLanguageCode),
            ),
            trailing: const Icon(Icons.access_time),
            onTap: _selectAlarmTime,
          ),
        ],
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.get('notes_optional', _currentLanguageCode),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: AppLocalizations.get('motivation_notes_hint', _currentLanguageCode),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveMotivation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
        ),
        child: Text(
          AppLocalizations.get('save_motivation', _currentLanguageCode),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _selectAlarmTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: alarmTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        alarmTime = picked;
      });
    }
  }

  void _saveMotivation() {
    if (_formKey.currentState!.validate()) {
      if (selectedFrequency == RoutineFrequency.weekly && selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.get('select_day', _currentLanguageCode))),
        );
        return;
      }

      final detailedTitle = selectedSubType != null 
          ? '${widget.baseMotivation['title']} - $selectedSubType'
          : widget.baseMotivation['title'];

      final detailedDescription = _buildDetailedDescription();

      final motivation = Routine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: detailedTitle,
        description: detailedDescription,
        category: widget.baseMotivation['category'],
        frequency: selectedFrequency,
        hasAlarm: hasAlarm,
        alarmTime: alarmTime,
        createdAt: DateTime.now(),
        targetMinutes: _isTimeBased ? (int.tryParse(_targetMinutesController.text) ?? 30) : 0,
        isTimeBased: _isTimeBased,
      );

      Navigator.pop(context, motivation);
    }
  }

  String _buildDetailedDescription() {
    String description = widget.baseMotivation['description'];
    
    if (selectedSubType != null) {
      description += ' ($selectedSubType)';
    }
    
    description += ' - ${_targetMinutesController.text} ${AppLocalizations.get('minutes', _currentLanguageCode)}';
    
    if (selectedFrequency == RoutineFrequency.weekly && selectedDays.isNotEmpty) {
      description += ' - ${selectedDays.join(', ')}';
    }
    
    if (_notesController.text.isNotEmpty) {
      description += ' - ${_notesController.text}';
    }
    
    return description;
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
        return AppLocalizations.get('daily', _currentLanguageCode);
      case RoutineFrequency.weekly:
        return AppLocalizations.get('weekly', _currentLanguageCode);
      case RoutineFrequency.monthly:
        return AppLocalizations.get('monthly', _currentLanguageCode);
    }
  }


}