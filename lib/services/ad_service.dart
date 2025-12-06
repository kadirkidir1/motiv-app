import 'dart:io';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/env_config.dart';

class AdService {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return EnvConfig.adMobAndroidBanner;
    } else if (Platform.isIOS) {
      return EnvConfig.adMobIosBanner;
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // Henüz oluşturulmadı, gerekirse AdMob'dan al
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      // Test ID - Gerçek ID ile değiştir
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return EnvConfig.adMobAndroidRewarded;
    } else if (Platform.isIOS) {
      return EnvConfig.adMobIosRewarded;
    }
    throw UnsupportedError('Unsupported platform');
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {},
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
  }

  static Future<InterstitialAd?> createInterstitialAd() async {
    InterstitialAd? interstitialAd;
    
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {},
      ),
    );
    
    return interstitialAd;
  }

  static Future<RewardedAd?> loadRewardedAd() async {
    final completer = Completer<RewardedAd?>();
    
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          completer.complete(null);
        },
      ),
    );
    
    return completer.future;
  }
}
