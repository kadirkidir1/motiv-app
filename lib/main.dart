import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/deep_link_service.dart';
import 'services/revenue_cat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://emrambokeqhcizknyudn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtcmFtYm9rZXFoY2l6a255dWRuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2NjE0MjAsImV4cCI6MjA3NTIzNzQyMH0.KR1Op9S7BuA3OOpXOPc1xoBUX3duFnyDLg6gm0qwhWA',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  await NotificationService.initialize();
  await NotificationService.rescheduleAllNotifications();
  await RevenueCatService.initialize();
  await DeepLinkService.initialize();

  runApp(const MotivApp());
}

class MotivApp extends StatelessWidget {
  const MotivApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motiv App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
