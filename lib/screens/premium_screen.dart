import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenue_cat_service.dart';

class PremiumScreen extends StatelessWidget {
  final String languageCode;

  const PremiumScreen({super.key, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final isTurkish = languageCode == 'tr';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTurkish ? 'Premium\'a Geç' : 'Go Premium'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade700, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium, size: 80, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    isTurkish ? 'Premium Üyelik' : 'Premium Membership',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTurkish
                        ? 'Tüm özelliklerin kilidini aç'
                        : 'Unlock all features',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTurkish ? 'Premium Özellikler' : 'Premium Features',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeature(
                    Icons.all_inclusive,
                    isTurkish ? 'Sınırsız Motivasyon' : 'Unlimited Motivations',
                    isTurkish
                        ? 'İstediğin kadar motivasyon ekle'
                        : 'Add as many motivations as you want',
                  ),
                  _buildFeature(
                    Icons.task_alt,
                    isTurkish ? 'Günlük Görevler' : 'Daily Tasks',
                    isTurkish
                        ? 'Zamana bağlı görevler oluştur'
                        : 'Create time-based tasks',
                  ),
                  _buildFeature(
                    Icons.analytics,
                    isTurkish ? 'Detaylı İstatistikler' : 'Advanced Statistics',
                    isTurkish
                        ? 'Grafikler ve ilerleme raporları'
                        : 'Charts and progress reports',
                  ),
                  _buildFeature(
                    Icons.calendar_month,
                    isTurkish ? 'Takvim Görünümü' : 'Calendar View',
                    isTurkish
                        ? 'Aktivitelerini takvimde gör'
                        : 'View activities in calendar',
                  ),
                  _buildFeature(
                    Icons.cloud_sync,
                    isTurkish ? 'Bulut Senkronizasyonu' : 'Cloud Sync',
                    isTurkish
                        ? 'Verilerini güvenle sakla'
                        : 'Store your data securely',
                  ),
                  const SizedBox(height: 32),
                  _buildPricingCard(context, isTurkish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.amber.shade700, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context, bool isTurkish) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.amber.shade50, Colors.orange.shade50],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₺',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
                Text(
                  '72',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
                Text(
                  '.00',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            Text(
              isTurkish ? '/yıl' : '/year',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              isTurkish ? 'Sadece ayda ₺6' : 'Only ₺6/month',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _handlePurchase(context, isTurkish),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isTurkish ? 'Premium\'a Geç' : 'Go Premium',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isTurkish
                  ? 'İlk 30 gün ücretsiz! İstediğin zaman iptal et.'
                  : 'First 30 days free! Cancel anytime.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handlePurchase(BuildContext context, bool isTurkish) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final packages = await RevenueCatService.getAvailablePackages();
      
      if (!context.mounted) return;
      Navigator.pop(context);

      if (packages.isEmpty) {
        _showError(context, isTurkish, isTurkish ? 'Paketler yüklenemedi' : 'Failed to load packages');
        return;
      }

      final yearlyPackage = packages.firstWhere(
        (p) => p.storeProduct.identifier == 'motiv_premium_yearly',
        orElse: () => packages.first,
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await RevenueCatService.purchasePackage(yearlyPackage);
      
      if (!context.mounted) return;
      Navigator.pop(context);

      if (success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(isTurkish ? 'Başarılı!' : 'Success!'),
              ],
            ),
            content: Text(
              isTurkish
                  ? 'Premium üyeliğiniz aktif edildi!'
                  : 'Your premium membership has been activated!',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(isTurkish ? 'Tamam' : 'OK'),
              ),
            ],
          ),
        );
      } else {
        _showError(context, isTurkish, isTurkish ? 'Satın alma iptal edildi' : 'Purchase cancelled');
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _showError(context, isTurkish, e.toString());
    }
  }

  void _showError(BuildContext context, bool isTurkish, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTurkish ? 'Hata' : 'Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTurkish ? 'Tamam' : 'OK'),
          ),
        ],
      ),
    );
  }
}
