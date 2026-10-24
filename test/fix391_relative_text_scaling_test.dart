import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/app/relative_text_scaler.dart';

void main() {
  test('relative compact factor preserves system scaling proportion', () {
    const baseline = RelativeTextScaler(TextScaler.linear(1.0));
    const enlarged = RelativeTextScaler(TextScaler.linear(1.5));

    expect(baseline.scale(10), 9);
    expect(enlarged.scale(10), 13.5);
  });
}
