import 'package:flutter/material.dart';

final ValueNotifier<String> themeNotifier = ValueNotifier<String>('emerald');

ThemeData buildAppTheme(String currentTheme) {
  if (currentTheme == 'emerald') {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3C7A67),
        primary: const Color(0xFF3C7A67),
        secondary: const Color(0xFF3C7A67),
        secondaryContainer: const Color(0xFFD9E8E0),
        surface: const Color(0xFFF3F1EC),
        onPrimary: Colors.white,
        onSurface: const Color(0xFF202724),
      ),
      fontFamily: 'Segoe UI',
    );
  } else if (currentTheme == 'cosmic') {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFC8B8FF),
        secondary: Color(0xFFC8B8FF),
        secondaryContainer: Color(0xFF3A2570),
        surface: Color(0xFF241840),
        onPrimary: Color(0xFF2B1450),
        onSurface: Color(0xFFF3ECFF),
      ),
      fontFamily: 'Segoe UI',
    );
  } else {
    // Default: sunset
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFA45833),
        primary: const Color(0xFFA45833),
        secondary: const Color(0xFFA45833),
        secondaryContainer: const Color(0xFFE6C2AF),
        surface: const Color(0xFFEEDBD0),
        onPrimary: Colors.white,
        onSurface: const Color(0xFF2D1B14),
      ),
      fontFamily: 'Segoe UI',
    );
  }
}
