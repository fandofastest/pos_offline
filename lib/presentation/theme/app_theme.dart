import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF2563EB);
  static const Color scaffoldBg = Color(0xFFF3F4F6);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: primary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      cardTheme: const CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      dividerTheme: DividerThemeData(color: Colors.black.withValues(alpha: 0.06), thickness: 1, space: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
        labelStyle: TextStyle(color: Colors.black.withValues(alpha: 0.75)),
        prefixIconColor: Colors.black.withValues(alpha: 0.55),
        suffixIconColor: Colors.black.withValues(alpha: 0.55),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      cardTheme: const CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.08), thickness: 1, space: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        prefixIconColor: Colors.white.withValues(alpha: 0.65),
        suffixIconColor: Colors.white.withValues(alpha: 0.65),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF1F2937)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF1F2937)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
