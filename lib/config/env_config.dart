class EnvConfig {
  // Supabase
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://emrambokeqhcizknyudn.supabase.co',
  );
  
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtcmFtYm9rZXFoY2l6a255dWRuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2NjE0MjAsImV4cCI6MjA3NTIzNzQyMH0.KR1Op9S7BuA3OOpXOPc1xoBUX3duFnyDLg6gm0qwhWA',
  );

  // RevenueCat
  static const revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: 'goog_VFcTaeVDnKvcmFgmYLCCFcewaGx',
  );

  // AdMob - Android
  static const adMobAndroidBanner = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER',
    defaultValue: 'ca-app-pub-9382614319631087/2695709461',
  );
  
  static const adMobAndroidRewarded = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED',
    defaultValue: 'ca-app-pub-9382614319631087/5486637725',
  );

  // AdMob - iOS (Test IDs - gerçekleriyle değiştir)
  static const adMobIosBanner = String.fromEnvironment(
    'ADMOB_IOS_BANNER',
    defaultValue: 'ca-app-pub-3940256099942544/2934735716',
  );
  
  static const adMobIosRewarded = String.fromEnvironment(
    'ADMOB_IOS_REWARDED',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  );

  // AdMob App IDs
  static const adMobAndroidAppId = String.fromEnvironment(
    'ADMOB_ANDROID_APP_ID',
    defaultValue: 'ca-app-pub-9382614319631087~1234567890',
  );
  
  static const adMobIosAppId = String.fromEnvironment(
    'ADMOB_IOS_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~1458002511',
  );
}
