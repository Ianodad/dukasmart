import 'package:flutter/material.dart';

/// DukaSmart design system — "Slate + Emerald Pro" (see /DESIGN.md, the
/// single source of truth for every token/style/ban below). Light theme
/// only: a bright-daylight kiosk POS tool.
///
/// Green-tinted slate neutrals carry the UI; emerald is reserved for
/// primary actions, success, and money-positive signals.
class AppTokens {
  AppTokens._();

  // --- Neutrals (green-tinted slate) ---
  static const Color bg = Color(0xFFF7FAF8);
  static const Color surface = Color(0xFFFCFDFD);
  static const Color surfaceMuted = Color(0xFFEDF1EE);
  static const Color surfaceDark = Color(0xFF182420);
  static const Color ink = Color(0xFF101915);
  static const Color inkSecondary = Color(0xFF51605A);
  static const Color inkMuted = Color(0xFF6F7D77);
  static const Color border = Color(0xFFDFE6E2);
  static const Color onDark = Color(0xFFF2F7F4);

  // --- Brand + semantic ---
  static const Color emerald = Color(0xFF059669);
  static const Color emeraldPressed = Color(0xFF047857);
  static const Color emeraldContainer = Color(0xFFD7F0E5);
  static const Color onEmerald = Color(0xFFF6FBF8);
  static const Color emeraldDeep = Color(0xFF065F46);
  static const Color amber = Color(0xFFB45309);
  static const Color amberContainer = Color(0xFFFBEED9);
  static const Color red = Color(0xFFD92D20);
  static const Color redContainer = Color(0xFFFDE8E6);
  static const Color blue = Color(0xFF2563EB);
  static const Color blueContainer = Color(0xFFE3EBFC);

  /// Soft card shadow: `rgba(16,25,21,0.06)` (ink at 6% opacity).
  static const Color cardShadow = Color(0x0F101915);

  static const String fontFamily = 'Lexend';
}

/// Backward-compatible palette. Existing feature screens (restyled in
/// later tasks) still compile against these names; each is remapped onto
/// the new [AppTokens] palette so the whole app reads as one system even
/// before every screen has its own restyle pass.
class AppColors {
  AppColors._();

  static const Color primary = AppTokens.emerald;
  static const Color success = AppTokens.emerald;
  static const Color warning = AppTokens.amber;
  static const Color error = AppTokens.red;
  static const Color mpesaAccent = AppTokens.blue;
  static const Color background = AppTokens.bg;
  static const Color charcoal = AppTokens.ink;
}

/// The full DESIGN.md type scale (≈1.2 ratio), bundled Lexend, tabular
/// figures on every money style. [totalLarge]/[totalMedium]/[totalSmall]
/// are the pre-redesign names, kept as aliases for
/// [moneyDisplay]/[moneyMedium]/[moneySmall] so untouched screens keep
/// compiling.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle moneyDisplay = TextStyle(
    fontFamily: AppTokens.fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppTokens.ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle moneyMedium = TextStyle(
    fontFamily: AppTokens.fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppTokens.ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle moneySmall = TextStyle(
    fontFamily: AppTokens.fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppTokens.ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle headline = TextStyle(
    fontFamily: AppTokens.fontFamily,
    fontSize: 23,
    fontWeight: FontWeight.w600,
    color: AppTokens.ink,
  );

  static const TextStyle title = TextStyle(
    fontFamily: AppTokens.fontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: AppTokens.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppTokens.fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppTokens.ink,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: AppTokens.fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppTokens.ink,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppTokens.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppTokens.inkSecondary,
  );

  /// Small-caps label above money (e.g. "TODAY'S SALES"). Callers pass
  /// already-uppercased text — [TextStyle] cannot transform case itself.
  static const TextStyle overline = TextStyle(
    fontFamily: AppTokens.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppTokens.inkMuted,
  );

  /// Pre-redesign aliases — kept so screens awaiting their restyle pass
  /// still compile against the old names.
  static const TextStyle totalLarge = moneyDisplay;
  static const TextStyle totalMedium = moneyMedium;
  static const TextStyle totalSmall = moneySmall;
}

ThemeData buildAppTheme() {
  final colorScheme = const ColorScheme.light(
    primary: AppTokens.emerald,
    onPrimary: AppTokens.onEmerald,
    secondary: AppTokens.inkSecondary,
    onSecondary: AppTokens.onDark,
    error: AppTokens.red,
    onError: AppTokens.onEmerald,
    surface: AppTokens.surface,
    onSurface: AppTokens.ink,
  ).copyWith(
    primaryContainer: AppTokens.emeraldContainer,
    onPrimaryContainer: AppTokens.emeraldDeep,
    secondaryContainer: AppTokens.surfaceMuted,
    onSecondaryContainer: AppTokens.ink,
    tertiary: AppTokens.blue,
    onTertiary: AppTokens.onEmerald,
    tertiaryContainer: AppTokens.blueContainer,
    onTertiaryContainer: AppTokens.blue,
    errorContainer: AppTokens.redContainer,
    onErrorContainer: AppTokens.red,
    surfaceContainerHighest: AppTokens.surfaceMuted,
    onSurfaceVariant: AppTokens.inkSecondary,
    outline: AppTokens.border,
    outlineVariant: AppTokens.border,
    shadow: AppTokens.ink,
    scrim: AppTokens.ink,
    inverseSurface: AppTokens.surfaceDark,
    onInverseSurface: AppTokens.onDark,
    inversePrimary: AppTokens.emeraldContainer,
    surfaceTint: Colors.transparent,
  );

  final baseTextTheme = ThemeData(brightness: Brightness.light).textTheme;
  final textTheme = baseTextTheme
      .copyWith(
        displayLarge: AppTextStyles.moneyDisplay,
        displayMedium: AppTextStyles.moneyMedium,
        displaySmall: AppTextStyles.moneySmall,
        headlineLarge: AppTextStyles.headline,
        headlineMedium: AppTextStyles.headline,
        headlineSmall: AppTextStyles.headline,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.title,
        titleSmall: AppTextStyles.bodyStrong,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.bodyStrong,
        labelMedium: AppTextStyles.caption,
        labelSmall: AppTextStyles.overline,
      )
      .apply(fontFamily: AppTokens.fontFamily);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppTokens.fontFamily,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppTokens.bg,
    textTheme: textTheme,
    dividerColor: AppTokens.border,
    splashFactory: InkRipple.splashFactory,

    // Dark-band app bar: onDark title LEFT-aligned, no elevation.
    appBarTheme: AppBarTheme(
      backgroundColor: AppTokens.surfaceDark,
      foregroundColor: AppTokens.onDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.headline.copyWith(color: AppTokens.onDark),
      iconTheme: const IconThemeData(color: AppTokens.onDark),
      actionsIconTheme: const IconThemeData(color: AppTokens.onDark),
    ),

    // Bottom nav: surface bar, emerald active + emeraldContainer
    // indicator, inkMuted inactive. Hairline top border is applied by the
    // app shell (NavigationBarThemeData has no border slot).
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppTokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: AppTokens.emeraldContainer,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? AppTokens.emerald : AppTokens.inkMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppTextStyles.caption.copyWith(
          color: states.contains(WidgetState.selected) ? AppTokens.emerald : AppTokens.inkMuted,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    ),

    // Primary = FilledButton. Colors resolve from ColorScheme.primary so
    // FilledButton.tonal (secondary) keeps its own surfaceMuted/ink look —
    // only shape/text/size are themed here.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        textStyle: AppTextStyles.bodyStrong,
        minimumSize: const Size(64, 48),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTokens.surfaceMuted,
        foregroundColor: AppTokens.ink,
        shape: const StadiumBorder(),
        textStyle: AppTextStyles.bodyStrong,
        minimumSize: const Size(64, 48),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppTokens.inkSecondary,
        textStyle: AppTextStyles.bodyStrong,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTokens.ink,
        side: const BorderSide(color: AppTokens.border),
        shape: const StadiumBorder(),
        textStyle: AppTextStyles.bodyStrong,
        minimumSize: const Size(64, 48),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppTokens.inkSecondary),
    ),

    // Filled inputs: surfaceMuted rest, emerald focus border, floating
    // labels, radius 12, no border at rest.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTokens.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: AppTextStyles.body.copyWith(color: AppTokens.inkMuted),
      hintStyle: AppTextStyles.body.copyWith(color: AppTokens.inkMuted),
      helperStyle: AppTextStyles.caption,
      errorStyle: AppTextStyles.caption.copyWith(color: AppTokens.red),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTokens.emerald, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTokens.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTokens.red, width: 1.5),
      ),
    ),

    // Cards: radius 14, hairline border, soft shadow, never tinted.
    cardTheme: CardThemeData(
      color: AppTokens.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppTokens.cardShadow,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTokens.border),
      ),
    ),

    // Chips: pill, tint container + deep text (per-widget colors set
    // where a chip carries semantic state, e.g. StockStatusChip).
    chipTheme: ChipThemeData(
      backgroundColor: AppTokens.surfaceMuted,
      labelStyle: AppTextStyles.caption.copyWith(color: AppTokens.inkSecondary),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    // Bottom sheets: surface, top radius 20, drag handle.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppTokens.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppTokens.border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // SnackBar: surfaceDark/onDark (matches inverseSurface/onInverseSurface
    // above, set explicitly so the look doesn't depend on Material
    // defaults).
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppTokens.surfaceDark,
      contentTextStyle: AppTextStyles.body.copyWith(color: AppTokens.onDark),
      actionTextColor: AppTokens.emeraldContainer,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppTokens.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTextStyles.title,
      contentTextStyle: AppTextStyles.body,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    listTileTheme: ListTileThemeData(
      textColor: AppTokens.ink,
      iconColor: AppTokens.inkSecondary,
      titleTextStyle: AppTextStyles.bodyStrong,
      subtitleTextStyle: AppTextStyles.caption,
    ),

    dividerTheme: const DividerThemeData(color: AppTokens.border, thickness: 1, space: 1),

    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppTokens.emerald),
  );
}
