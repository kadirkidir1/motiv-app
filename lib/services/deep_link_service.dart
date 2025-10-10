import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

class DeepLinkService {
  static final _appLinks = AppLinks();
  static bool _initialized = false;
  static GlobalKey<NavigatorState>? _navigatorKey;

  static Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_initialized) return;
    _initialized = true;
    _navigatorKey = navigatorKey;

    // Handle deep links when app is already running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Handle deep link that opened the app
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }
  }

  static void _handleDeepLink(Uri uri) async {
    if (uri.scheme == 'motivapp' && uri.host == 'login-callback') {
      try {
        // Check if this is a password reset BEFORE calling getSessionFromUrl
        final isPasswordReset = uri.fragment.contains('type=recovery') || 
                                uri.queryParameters['type'] == 'recovery';
        
        // Extract the OAuth tokens from the URI
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
        
        // Navigate to reset password screen if it's a password reset
        if (isPasswordReset) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (_navigatorKey?.currentContext != null) {
            final context = _navigatorKey!.currentContext!;
            Navigator.pushNamed(context, '/reset-password');
          }
        }
      } catch (e) {
        // Link expired or invalid, ignore
      }
    }
  }
}
