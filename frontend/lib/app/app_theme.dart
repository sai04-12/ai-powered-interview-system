import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors (matching the PDF Presentation)
  static const Color primary = Color(0xFF2563EB);        // Vibrant Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);    // Deep Blue
  static const Color primaryLight = Color(0xFF3B82F6);   // Blue 500
  static const Color primarySoft = Color(0xFFEFF6FF);    // Blue 50
  
  static const Color accent = Color(0xFF0EA5E9);         // Sky 500
  static const Color accentTeal = Color(0xFF14B8A6);     // Teal 500
  static const Color accentIndigo = Color(0xFF6366F1);   // Indigo 500

  // Neutral Light Theme (Primary theme for PDF accuracy)
  static const Color bgLight = Color(0xFFF8FAFC);        // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);   // Pure White
  static const Color cardBorderLight = Color(0xFFE2E8F0);// Slate 200
  static const Color cardHoverLight = Color(0xFFF1F5F9); // Slate 100
  static const Color textDark = Color(0xFF0F172A);       // Slate 900
  static const Color textMuted = Color(0xFF64748B);      // Slate 500
  static const Color textSubtle = Color(0xFF94A3B8);     // Slate 400

  // Dark Theme (for toggling)
  static const Color background = Color(0xFF0F172A);     // Slate 900
  static const Color surface = Color(0xFF1E293B);        // Slate 800
  static const Color surfaceElevated = Color(0xFF334155);// Slate 700
  static const Color textPrimary = Color(0xFFF8FAFC);    // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8);  // Slate 400

  // Status Colors
  static const Color success = Color(0xFF10B981);        // Emerald 500
  static const Color successSoft = Color(0xFFECFDF5);    // Emerald 50
  static const Color warning = Color(0xFFF59E0B);        // Amber 500
  static const Color warningSoft = Color(0xFFFFFBEB);    // Amber 50
  static const Color error = Color(0xFFEF4444);          // Rose 500
  static const Color errorSoft = Color(0xFFFEF2F2);      // Rose 50

  // PDF Exact Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surfaceLight,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
        onError: Colors.white,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: cardBorderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: cardBorderLight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cardBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cardBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSubtle, fontSize: 14),
        labelStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
    );
  }

  // Dark Theme Alternative
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: Color(0xFF475569)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
