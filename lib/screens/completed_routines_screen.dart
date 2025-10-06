import 'package:flutter/material.dart';
import '../models/motivation.dart';
import '../services/language_service.dart';

class CompletedRoutinesScreen extends StatefulWidget {
  final List<Motivation> completedRoutines;

  const CompletedRoutinesScreen({
    super.key,
    required this.completedRoutines,
  });

  @override
  State<CompletedRoutinesScreen> createState() => _CompletedRoutinesScreenState();
}

class _CompletedRoutinesScreenState extends State<CompletedRoutinesScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('completed_routines', _languageCode)),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: widget.completedRoutines.isEmpty
          ? _buildEmptyState()
          : _buildCompletedList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.get('no_completed_routines', _languageCode),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.get('completed_routines_desc', _languageCode),
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

  Widget _buildCompletedList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.completedRoutines.length,
      itemBuilder: (context, index) {
        final routine = widget.completedRoutines[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade600,
              child: const Icon(
                Icons.check,
                color: Colors.white,
              ),
            ),
            title: Text(
              routine.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(routine.description),
                const SizedBox(height: 4),
                Text(
                  '${AppLocalizations.get('routine_completed', _languageCode)} - ${_getCategoryName(routine.category)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              Icons.psychology,
              color: Colors.green.shade600,
            ),
          ),
        );
      },
    );
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
}