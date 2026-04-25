import 'package:flutter/material.dart';

class AppTheme {
  // Core palette — deep forest + warm amber
  static const Color bg = Color(0xFF0D1B14);
  static const Color surface = Color(0xFF142019);
  static const Color card = Color(0xFF1C2D22);
  static const Color cardAlt = Color(0xFF1A2A1E);
  static const Color navBg = Color(0xFF0F1C16);

  static const Color accent = Color(0xFF6FCF45); // lime green
  static const Color accentWarm = Color(0xFFE8A94C); // amber
  static const Color accentCool = Color(0xFF4CBFE8); // sky blue
  static const Color accentRed = Color(0xFFE85C4A); // alert red
  static const Color accentPurple = Color(0xFF9B6FE8); // prediction purple

  static const Color textPrimary = Color(0xFFF0F4EE);
  static const Color textSecondary = Color(0xFFB8C9B4);
  static const Color textMuted = Color(0xFF6B8A65);

  static const Color border = Color(0xFF2A3D2E);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Sora',
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentWarm,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Sora',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
