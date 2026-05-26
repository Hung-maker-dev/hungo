// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Bảng màu chủ đạo: Blue ───────────────────────────────────────────────
  static const Color primary     = Color(0xFF1565C0); // blue 800
  static const Color primaryLight= Color(0xFF1E88E5); // blue 600
  static const Color primaryDark = Color(0xFF0D47A1); // blue 900
  static const Color accent      = Color(0xFF29B6F6); // light blue 400
  static const Color success     = Color(0xFF2E7D32);
  static const Color warning     = Color(0xFFF57C00);
  static const Color error       = Color(0xFFC62828);

  // Level colors
  static const Color levelA1 = Color(0xFF66BB6A);
  static const Color levelA2 = Color(0xFF42A5F5);
  static const Color levelB1 = Color(0xFFFFCA28);
  static const Color levelB2 = Color(0xFFFFA726);
  static const Color levelC1 = Color(0xFFEF5350);
  static const Color levelC2 = Color(0xFF7B1FA2);

  // Skill colors
  static const Color skillVocab    = Color(0xFF1565C0);
  static const Color skillReading  = Color(0xFF6A1B9A);
  static const Color skillListening= Color(0xFFE65100);
  static const Color skillGrammar  = Color(0xFF2E7D32);

  static TextTheme _textTheme(Color textColor) => TextTheme(
    displayLarge : GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold,   color: textColor),
    displayMedium: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold,   color: textColor),
    headlineMedium:GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600,   color: textColor),
    titleLarge   : GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600,   color: textColor),
    titleMedium  : GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500,   color: textColor),
    bodyLarge    : GoogleFonts.inter(  fontSize: 15, fontWeight: FontWeight.normal, color: textColor),
    bodyMedium   : GoogleFonts.inter(  fontSize: 14, fontWeight: FontWeight.normal, color: textColor),
    labelLarge   : GoogleFonts.inter(  fontSize: 14, fontWeight: FontWeight.w600,   color: textColor),
  );

  // ── LIGHT THEME ───────────────────────────────────────────────────────────
  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(primary: primary, secondary: accent),
    textTheme: _textTheme(const Color(0xFF1A1A2E)),
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F7FF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: primary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // ── DARK THEME ────────────────────────────────────────────────────────────
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(primary: primaryLight, secondary: accent),
    textTheme: _textTheme(const Color(0xFFE8EAF6)),
    scaffoldBackgroundColor: const Color(0xFF0D1117),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF161B22),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF161B22),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1C2230),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF161B22),
      selectedItemColor: primaryLight,
      unselectedItemColor: Colors.grey.shade600,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
