import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildLightTheme() {
  const primaryColor = Color(0xFF4F46E5);      // Sovereign Indigo
  const accentColor = Color(0xFF0D9488);       // Clinical Teal
  const backgroundColor = Color(0xFFF5F6FA);   // Warm Porcelain
  const cardColor = Color(0xFFFFFFFF);         // Clean White
  const textColor = Color(0xFF0F172A);         // Obsidian Dark

  final base = ThemeData.light();

  return base.copyWith(
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: base.colorScheme.copyWith(
      primary: primaryColor,
      secondary: accentColor,
      surface: cardColor,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: textColor,
      displayColor: textColor,
    ),
    cardTheme: const CardThemeData(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Inter'),
      floatingLabelStyle: TextStyle(color: primaryColor, fontFamily: 'Inter'),
      prefixIconColor: const Color(0xFF64748B),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: textColor),
      titleTextStyle: GoogleFonts.sora(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  const primaryColor = Color(0xFF818CF8);      // Electric Indigo
  const accentColor = Color(0xFF2DD4BF);       // Electric Neon Teal
  const backgroundColor = Color(0xFF0B0F19);   // Abyssal Obsidian
  const cardColor = Color(0xFF141C2F);         // Elevated Slate-Navy
  const textColor = Color(0xFFF8FAFC);         // Pure Light Slate

  final base = ThemeData.dark();

  return base.copyWith(
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: base.colorScheme.copyWith(
      primary: primaryColor,
      secondary: accentColor,
      surface: cardColor,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: textColor,
      displayColor: textColor,
    ),
    cardTheme: const CardThemeData(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter'),
      floatingLabelStyle: TextStyle(color: primaryColor, fontFamily: 'Inter'),
      prefixIconColor: const Color(0xFF94A3B8),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: textColor),
      titleTextStyle: GoogleFonts.sora(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

ThemeData buildAppTheme() {
  return buildDarkTheme(); // Default theme fallback
}
