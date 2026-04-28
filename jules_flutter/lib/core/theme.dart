import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: AppColors.primary,
      dividerColor: const Color(0xFFD0D7DE),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme.copyWith(
          bodyLarge: const TextStyle(color: Color(0xFF1F2328)),
          bodyMedium: const TextStyle(color: Color(0xFF1F2328)),
          bodySmall: const TextStyle(color: Color(0xFF57606A)), // Darker gray for 6.5:1 contrast
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        surface: Color(0xFFF6F8FA),
        onSurface: Color(0xFF1F2328),
        outline: Color(0xFFD0D7DE),
        surfaceContainer: Color(0xFFEBEEF2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1F2328),
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.mainBg,
      primaryColor: AppColors.primary,
      dividerColor: AppColors.border,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          bodyLarge: const TextStyle(color: AppColors.textForeground),
          bodyMedium: const TextStyle(color: AppColors.textForeground),
          bodySmall: const TextStyle(color: Color(0xFFA5A5C7)), // Brighter muted color for 5.1:1 contrast on sidebar
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        surface: AppColors.sidebarBg,
        onSurface: AppColors.textForeground,
        outline: AppColors.border,
        surfaceContainer: Color(0xFF232334),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.mainBg,
        foregroundColor: AppColors.textForeground,
        elevation: 0,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(false),
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(8),
      ),
    );
  }
}
