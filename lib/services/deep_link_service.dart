import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  static final _appLinks = AppLinks();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

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

  static void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'motivapp' && uri.host == 'login-callback') {
      // Extract the OAuth tokens from the URI
      Supabase.instance.client.auth.getSessionFromUrl(uri);
    }
  }
}
