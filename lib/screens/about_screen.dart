import 'package:flutter/material.dart';
import '../services/language_service.dart';

class AboutScreen extends StatelessWidget {
  final String languageCode;

  const AboutScreen({
    super.key,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('about', languageCode)),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppInfo(),
            const SizedBox(height: 24),
            _buildFeatures(),
            const SizedBox(height: 24),
            _buildLegalInfo(),
            const SizedBox(height: 24),
            _buildContact(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.psychology,
              size: 80,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.get('app_name', languageCode),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.get('version', languageCode),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.get('app_description', languageCode),
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.get('features', languageCode),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.dashboard,
              AppLocalizations.get('dashboard_feature', languageCode),
              AppLocalizations.get('dashboard_desc', languageCode),
            ),
            _buildFeatureItem(
              Icons.track_changes,
              AppLocalizations.get('progress_tracking', languageCode),
              AppLocalizations.get('progress_desc', languageCode),
            ),
            _buildFeatureItem(
              Icons.note_add,
              AppLocalizations.get('daily_notes_feature', languageCode),
              AppLocalizations.get('daily_notes_desc', languageCode),
            ),
            _buildFeatureItem(
              Icons.alarm,
              AppLocalizations.get('reminders', languageCode),
              AppLocalizations.get('reminders_desc', languageCode),
            ),
            _buildFeatureItem(
              Icons.category,
              AppLocalizations.get('categories_feature', languageCode),
              AppLocalizations.get('categories_desc', languageCode),
            ),
            _buildFeatureItem(
              Icons.analytics,
              AppLocalizations.get('detailed_analysis', languageCode),
              AppLocalizations.get('analysis_desc', languageCode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue.shade600,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.get('legal_info', languageCode),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLegalSection(
              AppLocalizations.get('copyright_title', languageCode),
              AppLocalizations.get('copyright_desc', languageCode),
            ),
            _buildLegalSection(
              AppLocalizations.get('privacy_title', languageCode),
              AppLocalizations.get('privacy_desc', languageCode),
            ),
            _buildLegalSection(
              AppLocalizations.get('terms_title', languageCode),
              AppLocalizations.get('terms_desc', languageCode),
            ),
            _buildLegalSection(
              AppLocalizations.get('disclaimer_title', languageCode),
              AppLocalizations.get('disclaimer_desc', languageCode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContact() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.get('contact', languageCode),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              Icons.email,
              AppLocalizations.get('email', languageCode),
              'destek@motivapp.com',
            ),
            _buildContactItem(
              Icons.web,
              AppLocalizations.get('website', languageCode),
              'www.motivapp.com',
            ),
            _buildContactItem(
              Icons.bug_report,
              AppLocalizations.get('bug_report', languageCode),
              AppLocalizations.get('bug_report_desc', languageCode),
            ),
            _buildContactItem(
              Icons.star,
              AppLocalizations.get('rating', languageCode),
              AppLocalizations.get('rating_desc', languageCode),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.get('feedback_message', languageCode),
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue.shade600,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}