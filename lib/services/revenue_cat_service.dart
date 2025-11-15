import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RevenueCatService {
  static final _supabase = Supabase.instance.client;
  static const _apiKey = 'goog_VFcTaeVDnKvcmFgmYLCCFcewaGx';

  static Future<void> initialize() async {
    if (_apiKey == 'YOUR_REVENUECAT_API_KEY') {
      return; // API key henüz ayarlanmamış, atla
    }

    try {
      await Purchases.setLogLevel(LogLevel.debug);

      final config = PurchasesConfiguration(_apiKey);
      await Purchases.configure(config);

      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await Purchases.logIn(userId);
      }

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _syncPremiumStatus(customerInfo);
      });
    } catch (e) {
      // RevenueCat başlatılamadı, devam et
    }
  }

  static Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      return null;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      await _syncPremiumStatus(customerInfo);
      return customerInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      await _syncPremiumStatus(customerInfo);
      return customerInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Package>> getAvailablePackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      
      if (offerings.current != null) {
        return offerings.current!.availablePackages;
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> showManagementScreen() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.managementURL != null) {
        // RevenueCat'in sağladığı yönetim URL'ini kullan
        // Bu URL Google Play veya App Store'a yönlendirir
        // URL'yi açmak için url_launcher paketi gerekli
        // Şimdilik sadece bilgi döndür
        return;
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _syncPremiumStatus(CustomerInfo customerInfo) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final isPremium = customerInfo.entitlements.active.containsKey('premium');
    final expiryDate =
        customerInfo.entitlements.active['premium']?.expirationDate;

    await _supabase.from('profiles').update({
      'subscription_type': isPremium ? 'premium' : 'free',
      'premium_until': expiryDate,
    }).eq('id', userId);
  }
}
