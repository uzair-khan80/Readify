import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;
  bool get isDarkMode => _mode == ThemeMode.dark;

  void toggleTheme() {
    _mode = (_mode == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.black87),
        ),
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF0F1724),
        cardColor: const Color(0xFF1E293B),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFFFD700)), // golden text
          titleLarge: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Color(0xFFFFD700)),
        ),
      );
}
