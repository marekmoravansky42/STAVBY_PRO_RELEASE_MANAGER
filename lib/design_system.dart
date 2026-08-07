import 'package:flutter/material.dart';

import 'shared/theme/rm_color_scheme.dart';
import 'shared/theme/rm_dimensions.dart';
import 'shared/theme/rm_spacing.dart';

export 'shared/layout/rm_adaptive_layout.dart';
export 'shared/theme/rm_theme_exports.dart';
export 'shared/widgets/rm_widgets.dart';

/// Backward-compatible facade for existing UI code.
///
/// New components should import the focused classes from `shared/theme`.
abstract final class RMDesign {
  static const double sidebarCompactWidth = RMDimensions.sidebarCompactWidth;
  static const double sidebarExtendedWidth = RMDimensions.sidebarExtendedWidth;

  static const double radiusSmall = RMDimensions.radiusSmall;
  static const double controlRadius = RMDimensions.controlRadius;
  static const double cardRadius = RMDimensions.cardRadius;
  static const double radiusLarge = RMDimensions.radiusLarge;

  static const double controlHeight = RMDimensions.controlHeight;
  static const double compactControlHeight = RMDimensions.compactControlHeight;
  static const double iconBoxSize = RMDimensions.iconBoxSize;

  static const double space4 = RMSpacing.xxs;
  static const double space8 = RMSpacing.xs;
  static const double space12 = RMSpacing.sm;
  static const double space16 = RMSpacing.md;
  static const double space24 = RMSpacing.lg;

  static const double pageGap = RMSpacing.pageGap;
  static const EdgeInsets pagePadding = RMSpacing.pagePadding;
  static const EdgeInsets cardPadding = RMSpacing.cardPadding;
  static const EdgeInsets sectionHeaderPadding = RMSpacing.sectionHeaderPadding;
  static const EdgeInsets controlPadding = RMSpacing.controlPadding;

  static const Duration animationFast = Duration(milliseconds: 160);
  static const Duration animationNormal = Duration(milliseconds: 220);

  static Color scaffold(Brightness brightness) =>
      RMColorScheme.scaffold(brightness);
  static Color surface(Brightness brightness) =>
      RMColorScheme.surface(brightness);
  static Color surfaceLow(Brightness brightness) =>
      RMColorScheme.surfaceLow(brightness);
  static Color border(Brightness brightness) =>
      RMColorScheme.border(brightness);
}
