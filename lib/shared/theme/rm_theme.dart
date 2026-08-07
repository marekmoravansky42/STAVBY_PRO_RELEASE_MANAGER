import 'package:flutter/material.dart';

import 'rm_color_scheme.dart';
import 'rm_dimensions.dart';
import 'rm_spacing.dart';
import 'rm_theme_extensions.dart';
import 'rm_typography.dart';

/// Builds the complete Material theme from centralized Release Manager tokens.
abstract final class RMTheme {
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: RMColorScheme.seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: RMColorScheme.scaffold(brightness),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      extensions: <ThemeExtension<dynamic>>[
        RMThemeExtension.forBrightness(brightness),
      ],
      dividerTheme: DividerThemeData(
        color: RMColorScheme.border(brightness),
        thickness: 1,
        space: 1,
      ),
      textTheme: RMTypography.textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: RMColorScheme.surface(brightness),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: RMColorScheme.text(brightness),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: dark ? 0 : 2,
        shadowColor: RMColorScheme.cardShadow,
        margin: EdgeInsets.zero,
        color: RMColorScheme.surface(brightness),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RMDimensions.cardRadius),
          side: BorderSide(color: RMColorScheme.border(brightness)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: RMSpacing.controlPadding,
        filled: true,
        fillColor: RMColorScheme.surfaceLow(brightness),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RMDimensions.controlRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RMDimensions.controlRadius),
          borderSide: BorderSide(
            color: RMColorScheme.controlBorder(brightness),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, RMDimensions.controlHeight),
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RMDimensions.cardRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, RMDimensions.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RMDimensions.cardRadius),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        width: 460,
        elevation: 12,
        backgroundColor: dark ? const Color(0xFF172027) : const Color(0xFF1F2933),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: const Color(0xFF7DD3FC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: dark ? const Color(0xFF334155) : const Color(0xFF475569),
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: RMColorScheme.surface(brightness),
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
