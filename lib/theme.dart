import 'package:flutter/material.dart';

class AppTheme {
  // --- BRAND ---
  
  static const Color accent     = Color(0xFFFFD700);
  static const Color accentDim  = Color(0x33FFD700);
  static const Color success    = Color(0xFF22C55E);
  static const Color warning    = Color(0xFFF59E0B);
  static const Color danger     = Color(0xFFEF4444);

  // --- DARK PALETTE ---
  static const Color darkBg        = Color(0xFF0A0A0A);
  static const Color darkSurface   = Color(0xFF141414);
  static const Color darkCard      = Color(0xFF1E1E1E);
  static const Color darkBorder    = Color(0xFF2A2A2A);
  static const Color darkTextPri   = Color(0xFFF5F5F5);
  static const Color darkTextSec   = Color(0xFF9E9E9E);
  static const Color darkTextHint  = Color(0xFF5A5A5A);

  // --- LIGHT PALETTE ---
  static const Color lightBg       = Color(0xFFF7F7F7);
  static const Color lightSurface  = Color(0xFFFFFFFF);
  static const Color lightCard     = Color(0xFFFFFFFF);
  static const Color lightBorder   = Color(0xFFE5E5E5);
  static const Color lightTextPri  = Color(0xFF0A0A0A);
  static const Color lightTextSec  = Color(0xFF5A5A5A);
  static const Color lightTextHint = Color(0xFFAAAAAA);


  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    primaryColor: accent,
    colorScheme: const ColorScheme.dark(
      primary: accent, surface: darkSurface, error: danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg, elevation: 0, centerTitle: true,
      titleTextStyle: TextStyle(color: darkTextPri, fontSize: 17,
          fontWeight: FontWeight.w600, letterSpacing: -0.3),
      iconTheme: IconThemeData(color: darkTextPri),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent, foregroundColor: darkBg, elevation: 0,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: darkCard,
      hintStyle: const TextStyle(color: darkTextHint, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface, selectedItemColor: accent,
      unselectedItemColor: darkTextHint, type: BottomNavigationBarType.fixed, elevation: 0,
    ),
    dividerColor: darkBorder, cardColor: darkCard,
  );

  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    primaryColor: accent,
    colorScheme: const ColorScheme.light(
      primary: accent, surface: lightSurface, error: danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurface, elevation: 0, centerTitle: true,
      titleTextStyle: TextStyle(color: lightTextPri, fontSize: 17,
          fontWeight: FontWeight.w600, letterSpacing: -0.3),
      iconTheme: IconThemeData(color: lightTextPri),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent, foregroundColor: lightBg, elevation: 0,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: lightSurface,
      hintStyle: const TextStyle(color: lightTextHint, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurface, selectedItemColor: accent,
      unselectedItemColor: lightTextHint, type: BottomNavigationBarType.fixed, elevation: 0,
    ),
    dividerColor: lightBorder, cardColor: lightCard,
  );

  static Color? get black => null;

  static get surface => null;

  static get textHint => null;

  static Color? get card => null;

  static Color? get textSecond => null;

  static Color? get textPrimary => null;

  static get body => null;

  static get display => null;

  static Color? get cardBorder => null;
}

// --- DYNAMIC COLORS (reads current brightness) ---
class AppColors {
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkBg : AppTheme.lightBg;
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkSurface : AppTheme.lightSurface;
  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkCard : AppTheme.lightCard;
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkBorder : AppTheme.lightBorder;
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkTextPri : AppTheme.lightTextPri;
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkTextSec : AppTheme.lightTextSec;
  static Color textHint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkTextHint : AppTheme.lightTextHint;
}

// --- TEXT STYLES ---
class AppText {
  static const display = TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
      letterSpacing: -0.5, height: 1.2);
  static const heading = TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
      letterSpacing: -0.3);
  static const title = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
  static const label = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
}