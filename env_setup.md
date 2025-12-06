# Environment Setup Guide

## Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- Android Studio / VS Code
- Git

## Environment Configuration

### 1. Create Environment Config File
Create `lib/config/env_config.dart`:

```dart
class EnvConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String revenueCatApiKey = 'YOUR_REVENUECAT_API_KEY';
  static const String admobAppId = 'YOUR_ADMOB_APP_ID';
}
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Platform Setup

#### Android
- Update `android/app/build.gradle` minSdkVersion to 21+
- Add internet permission in `android/app/src/main/AndroidManifest.xml`

#### iOS
- Update `ios/Runner/Info.plist` for required permissions
- Set minimum iOS version to 11.0+

### 4. Service Configuration
- Supabase: Database and authentication
- RevenueCat: In-app purchases
- AdMob: Advertisement integration
- Firebase: Push notifications

### 5. Run the App
```bash
flutter run
```