import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: Colors.deepPurple,
  scaffoldBackgroundColor: const Color(0xFF0F0F12),

  cardTheme: CardThemeData(
    color: const Color(0xFF17171D),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0F0F12),
    foregroundColor: Colors.white,
    centerTitle: true,
    elevation: 0,
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF17171D),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  ),
);
