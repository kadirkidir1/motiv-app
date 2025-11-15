import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _key = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue.shade600,
      scaffoldBackgroundColor: Colors.grey.shade50,
      cardColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.blue.shade600,
        secondary: Colors.blue.shade400,
        surface: Colors.white,
        error: Colors.red.shade600,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue.shade400,
      scaffoldBackgroundColor: const Color(0xFF1C1C1E),
      cardColor: const Color(0xFF2C2C2E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2C2C2E),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      colorScheme: ColorScheme.dark(
        primary: Colors.blue.shade400,
        secondary: Colors.blue.shade300,
        surface: const Color(0xFF2C2C2E),
        error: Colors.red.shade400,
        onSurface: Colors.white,
        onPrimary: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF2C2C2E),
        elevation: 2,
      ),
      dividerColor: Colors.grey.shade700,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}
