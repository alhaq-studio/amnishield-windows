import 'package:flutter/material.dart';

final ValueNotifier<String> themeNotifier = ValueNotifier<String>('emerald');

ThemeData buildAppTheme(String currentTheme) {
  if (currentTheme == 'emerald') {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF10B981),
        primary: const Color(0xFF059669),
        secondary: const Color(0xFFD4AF37),
        secondaryContainer: const Color(0xFFD1FAE5),
        surface: const Color(0xFFF8F9FC),
        onPrimary: Colors.white,
        onSurface: const Color(0xFF0A2540),
      ),
      fontFamily: 'Segoe UI',
    );
  } else if (currentTheme == 'cosmic') {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFD4AF37),
        secondary: Color(0xFF10B981),
        secondaryContainer: Color(0xFF1E293B),
        surface: Color(0xFF0F172A),
        onPrimary: Color(0xFF0A2540),
        onSurface: Color(0xFFF8FAFC),
      ),
      fontFamily: 'Segoe UI',
    );
  } else {
    // Default: Deep Navy & Royal Gold (Al-Haq Studio Signature)
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0A2540),
        primary: const Color(0xFF0A2540),
        secondary: const Color(0xFFD4AF37),
        secondaryContainer: const Color(0xFFFEF3C7),
        surface: const Color(0xFFF8F9FC),
        onPrimary: Colors.white,
        onSurface: const Color(0xFF0A2540),
      ),
      fontFamily: 'Segoe UI',
    );
  }
}
