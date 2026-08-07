import 'package:flutter/material.dart';

import '../shared/theme/rm_theme.dart';

/// Compatibility entry point for the application theme.
abstract final class AppTheme {
  static ThemeData build(Brightness brightness) => RMTheme.build(brightness);
}
