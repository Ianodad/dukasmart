import 'package:flutter/material.dart';

/// Design direction (requirements §Design direction): dark green primary,
/// white/light-grey background, charcoal text, soft green success, amber
/// low-stock, red errors/out-of-stock, blue for M-PESA info (no M-PESA
/// branding).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1B5E20);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFFFA000); // amber — low stock
  static const Color error = Color(0xFFD32F2F); // red — errors / out of stock
  static const Color mpesaAccent = Color(0xFF1565C0); // blue — M-PESA info only
  static const Color background = Color(0xFFF5F5F5);
  static const Color charcoal = Color(0xFF212121);
}

/// Large, legible text styles for financial totals (requirements §Design
/// direction: "large financial totals").
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle totalLarge = TextStyle(fontSize: 34, fontWeight: FontWeight.bold);
  static const TextStyle totalMedium = TextStyle(fontSize: 24, fontWeight: FontWeight.w700);
  static const TextStyle totalSmall = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: ThemeData.light().textTheme.apply(bodyColor: AppColors.charcoal, displayColor: AppColors.charcoal),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: colorScheme.primaryContainer,
    ),
  );
}
