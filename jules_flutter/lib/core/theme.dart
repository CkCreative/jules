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
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(false),
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1F2328),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1F2328)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary.withValues(alpha: 0.3);
          return null;
        }),
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
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textForeground,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF232334),
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        textStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textForeground),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary.withValues(alpha: 0.3);
          return null;
        }),
      ),
    );
  }
}
