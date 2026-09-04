import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SmartBankApp());
}

class SmartBankApp extends StatefulWidget {
  const SmartBankApp({super.key});

  @override
  State<SmartBankApp> createState() => _SmartBankAppState();
}

class _SmartBankAppState extends State<SmartBankApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartBank',
      themeMode: _themeMode,

      // =========================
      // LIGHT THEME
      // =========================

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),

      // =========================
      // DARK THEME
      // =========================

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),

      // =========================
      // FIRST SCREEN
      // =========================

      home: LoginScreen(
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}