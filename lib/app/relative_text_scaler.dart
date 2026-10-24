import 'package:flutter/widgets.dart';

/// Applies the application's compact design factor without discarding the
/// system's chosen text scaling behavior.
class RelativeTextScaler extends TextScaler {
  const RelativeTextScaler(this.base, {this.factor = 0.90});

  final TextScaler base;
  final double factor;

  @override
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;
}
