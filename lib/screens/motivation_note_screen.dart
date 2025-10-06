import 'package:flutter/material.dart';
import '../models/motivation.dart';
import '../models/daily_note.dart';

class MotivationNoteScreen extends StatefulWidget {
  final List<Motivation> motivations;

  const MotivationNoteScreen({
    super.key,
    required this.motivations,
  });

  @override
  State<MotivationNoteScreen> createState() => _MotivationNoteScreenState();
}

class _MotivationNoteScreenState extends State<MotivationNoteScreen> {
  Motivation? selectedMotivation;
  final _noteController = TextEditingController();
  int selectedMood = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motivasyon Notu Ekle'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMotivationSelector(),
            const SizedBox(height: 24),
            if (selectedMotivation != null) ...[
              _buildSelectedMotivationCard(),
              const SizedBox(height: 24),
              _buildNoteInput(),
              const SizedBox(height: 24),
              _buildMoodSelector(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hangi motivasyon için not eklemek istiyorsun?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.motivations.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Henüz motivasyon eklenmemiş. Önce bir motivasyon ekle.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...widget.motivations.map((motivation) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(motivation.category),
                  child: Icon(
                    _getCategoryIcon(motivation.category),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  motivation.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(motivation.description),
                trailing: selectedMotivation?.id == motivation.id
                    ? Icon(Icons.check_circle, color: Colors.green.shade600)
                    : const Icon(Icons.radio_button_unchecked),
                onTap: () {
                  setState(() {
                    selectedMotivation = motivation;
                  });
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSelectedMotivationCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getCategoryColor(selectedMotivation!.category),
              child: Icon(
                _getCategoryIcon(selectedMotivation!.category),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedMotivation!.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Seçili motivasyon',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notun',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            hintText: 'Bu motivasyon hakkında bugün neler yaşadın? Nasıl hissettin?',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bu motivasyon için bugün ruh halin nasıl?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selectedMood == mood
                      ? _getMoodColor(mood)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedMood == mood
                        ? _getMoodColor(mood)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _getMoodEmoji(mood),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getMoodText(mood),
                      style: TextStyle(
                        fontSize: 12,
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
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _noteController.text.isNotEmpty ? _saveNote : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
        ),
        child: const Text(
          'Notu Kaydet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _saveNote() {
    if (selectedMotivation == null || _noteController.text.isEmpty) return;

    final note = DailyNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      motivationId: selectedMotivation!.id,
      date: DateTime.now(),
      note: _noteController.text,
      mood: selectedMood,
    );

    Navigator.pop(context, note);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedMotivation!.title} için not kaydedildi!'),
        backgroundColor: Colors.green.shade600,
      ),
    );
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
        return 'Kötü';
      case 2:
        return 'Zor';
      case 3:
        return 'Normal';
      case 4:
        return 'İyi';
      case 5:
        return 'Harika';
      default:
        return 'Normal';
    }
  }
}