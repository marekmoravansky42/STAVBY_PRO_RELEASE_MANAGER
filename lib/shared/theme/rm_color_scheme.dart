import 'package:flutter/material.dart';

/// Central color tokens used by the Release Manager desktop interface.
abstract final class RMColorScheme {
  static const Color seed = Color(0xFF1F5C78);

  static const Color lightScaffold = Color(0xFFF2F5F7);
  static const Color darkScaffold = Color(0xFF101518);

  static const Color lightSurface = Colors.white;
  static const Color darkSurface = Color(0xFF182126);

  static const Color lightSurfaceLow = Color(0xFFF7F9FA);
  static const Color darkSurfaceLow = Color(0xFF202B31);

  static const Color lightBorder = Color(0xFFDCE5E9);
  static const Color darkBorder = Color(0xFF334047);

  static const Color lightControlBorder = Color(0xFFD5DCE2);
  static const Color darkControlBorder = Color(0xFF435159);

  static const Color lightText = Color(0xFF17212B);
  static const Color darkText = Color(0xFFF0F5F7);

  static const Color cardShadow = Color(0x241F5C78);

  static Color scaffold(Brightness brightness) =>
      brightness == Brightness.dark ? darkScaffold : lightScaffold;

  static Color surface(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : lightSurface;

  static Color surfaceLow(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurfaceLow : lightSurfaceLow;

  static Color border(Brightness brightness) =>
      brightness == Brightness.dark ? darkBorder : lightBorder;

  static Color controlBorder(Brightness brightness) =>
      brightness == Brightness.dark ? darkControlBorder : lightControlBorder;

  static Color text(Brightness brightness) =>
      brightness == Brightness.dark ? darkText : lightText;
}
