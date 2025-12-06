import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/reset_password_screen.dart';
import 'services/notification_service.dart';
import 'services/deep_link_service.dart';
import 'services/revenue_cat_service.dart';
import 'services/ad_service.dart';
import 'services/theme_service.dart';
import 'config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  await NotificationService.initialize();
  await NotificationService.rescheduleAllNotifications();
  await RevenueCatService.initialize();
  await AdService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const MotivApp(),
    ),
  );
}

class MotivApp extends StatefulWidget {
  const MotivApp({super.key});

  @override
  State<MotivApp> createState() => _MotivAppState();
}

class _MotivAppState extends State<MotivApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
    DeepLinkService.initialize(navigatorKey: navigatorKey);
  }

  void _listenToNotifications() {
    NotificationService.notificationStream.listen((payload) {
      // Bildirime tıklandığında ilgili ekrana git
      if (payload.startsWith('task_')) {
        // Task ekranına git
        navigatorKey.currentState?.pushNamed('/tasks');
      } else if (payload.startsWith('motivation_') || payload.startsWith('routine_')) {
        // Rutin ekranına git
        navigatorKey.currentState?.pushNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Motiv App',
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          themeMode: themeService.themeMode,
          home: const SplashScreen(),
          routes: {
            '/reset-password': (context) => const ResetPasswordScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
