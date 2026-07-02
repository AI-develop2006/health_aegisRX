import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const primaryColor = Color(0xFF0F52BA); // Deep sovereign blue
  const accentColor = Color(0xFF00A86B);  // Emerald green
  const backgroundColor = Color(0xFF0B0F19); // Dark background

  final base = ThemeData.dark();

  return base.copyWith(
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: base.colorScheme.copyWith(
      primary: primaryColor,
      secondary: accentColor,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF141A2A),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
