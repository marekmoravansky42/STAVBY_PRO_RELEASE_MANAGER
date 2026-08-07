import 'package:flutter/material.dart';

/// Central typography configuration for all workspaces.
abstract final class RMTypography {
  static const TextTheme textTheme = TextTheme(
    headlineSmall: TextStyle(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(fontWeight: FontWeight.w700),
    labelLarge: TextStyle(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
  );
}
