import 'package:flutter/material.dart';

/// Semantic colors that are not part of Material's base [ColorScheme].
@immutable
class RMThemeExtension extends ThemeExtension<RMThemeExtension> {
  const RMThemeExtension({
    required this.success,
    required this.warning,
    required this.info,
  });

  final Color success;
  final Color warning;
  final Color info;

  static RMThemeExtension forBrightness(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return RMThemeExtension(
      success: dark ? const Color(0xFF73D49A) : const Color(0xFF187A45),
      warning: dark ? const Color(0xFFFFC66D) : const Color(0xFF9A5A00),
      info: dark ? const Color(0xFF78C7FF) : const Color(0xFF156A9E),
    );
  }

  @override
  RMThemeExtension copyWith({Color? success, Color? warning, Color? info}) {
    return RMThemeExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  RMThemeExtension lerp(covariant RMThemeExtension? other, double t) {
    if (other == null) return this;
    return RMThemeExtension(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
    );
  }
}
