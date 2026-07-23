import 'package:flutter/material.dart';

/// Standard Professional Dark Theme Palette (GitHub / JetBrains Dark Aesthetic)
class AppColors {
  // Deep Neutral Backgrounds
  static const bgDark = Color(0xFF0D1117);      // GitHub Dark Canvas
  static const bgSidebar = Color(0xFF161B22);   // GitHub Dark Sidebar
  static const bgCard = Color(0xFF161B22);      // GitHub Dark Card
  static const bgHover = Color(0xFF21262D);     // Subtle Hover
  static const bgInput = Color(0xFF0D1117);     // Input Background
  static const borderColor = Color(0xFF30363D); // Soft Neutral Border

  // Professional Muted Accents (No bright yellow or neon blue)
  static const firebaseGold = Color(0xFF58A6FF);  // Soft Accent Blue/Cyan
  static const accentOrange = Color(0xFFD29922);  // Muted Soft Amber
  static const accentBlue = Color(0xFF58A6FF);    // Professional GitHub Blue
  static const accentGreen = Color(0xFF3FB950);   // Soft Muted Green
  static const accentRed = Color(0xFFF85149);     // Soft Muted Red

  // Professional Typography Colors
  static const textMain = Color(0xFFC9D1D9);    // Crisp Soft Silver/White
  static const textMuted = Color(0xFF8B949E);   // Muted Cool Gray
  static const textDim = Color(0xFF484F58);     // Dim Gray
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.bgDark,
      canvasColor: AppColors.bgSidebar,
      cardColor: AppColors.bgCard,
      dialogTheme: const DialogThemeData(backgroundColor: AppColors.bgCard),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgSidebar,
        contentTextStyle: const TextStyle(
          color: AppColors.textMain,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.borderColor),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentBlue,
        secondary: AppColors.accentBlue,
        surface: AppColors.bgCard,
        error: AppColors.accentRed,
      ),
      dividerColor: AppColors.borderColor,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textMain, fontSize: 13),
        bodySmall: TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
    );
  }
}
