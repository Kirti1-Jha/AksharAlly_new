import 'package:flutter/material.dart';

class AppTheme {
  // COLORS
  static const Color primaryPink = Color(0xFFE7B5C3);
  static const Color peachButton = Color(0xFFF5A77A);
  static const Color primaryGreen = Color(0xFF4CAF93);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color background = Color(0xFFF9F9F9);
  static const Color textDark = Color(0xFF2E2E2E);

  // ✅ REUSABLE TEXT STYLES (ADD THEM HERE)
  static const TextStyle headingStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textDark,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // THEME
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: background,
    fontFamily: 'Roboto',

    textTheme: const TextTheme(
      headlineMedium: headingStyle,
      bodyMedium: bodyStyle,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    ),
  );
}