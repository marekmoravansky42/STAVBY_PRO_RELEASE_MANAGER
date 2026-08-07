import 'package:flutter/widgets.dart';

/// Shared spacing and padding tokens.
abstract final class RMSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;

  static const double pageGap = xs;
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(10, 8, 10, 10);
  static const EdgeInsets cardPadding = EdgeInsets.all(12);
  static const EdgeInsets sectionHeaderPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 9,
  );
  static const EdgeInsets controlPadding = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 7,
  );
}
