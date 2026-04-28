import 'package:flutter/material.dart';

class AppColors {
  static const Color sidebarBg = Color(0xFF1E1E2E);
  static const Color mainBg = Color(0xFF0F0F1A);
  static const Color sidebarBorder = Color(0xFF2B2B3B);
  static const Color border = Color(0xFF2B2B3B);
  
  static const Color textForeground = Color(0xFFE0E0E0);
  static const Color textMuted = Color(0xFF9494B8);
  
  static const Color macRed = Color(0xFFFF5F56);
  static const Color macYellow = Color(0xFFFFBD2E);
  static const Color macGreen = Color(0xFF27C93F);
  
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryForeground = Colors.white;
  
  // Dark Diff Colors
  static const Color diffAddedBgDark = Color(0xFF112D1F);
  static const Color diffRemovedBgDark = Color(0xFF3D1111);
  static const Color diffAddedLineDark = Color(0xFF27C93F);
  static const Color diffRemovedLineDark = Color(0xFFFF5F56);

  // Light Diff Colors
  static const Color diffAddedBgLight = Color(0xFFE6FFEC);
  static const Color diffRemovedBgLight = Color(0xFFFFE7E7);
  static const Color diffAddedLineLight = Color(0xFF1F883D);
  static const Color diffRemovedLineLight = Color(0xFFCF222E);
  static const Color diffLineNumberLight = Color(0xFF6E7781);

  static const Color filePillBg = Color(0x1FFFFFFF);
}

class AppConstants {
  static const double sidebarWidth = 256.0;
  static const double chatAreaMinWidth = 400.0;
  static const double chatAreaMaxWidth = 500.0;
  static const double mobileBreakpoint = 800.0;
  static const double tabletBreakpoint = 1100.0;
  static const double resizerWidth = 1.0;
  
  static const double headerHeight = 48.0;
  static const double inputAreaHeight = 120.0;
}
