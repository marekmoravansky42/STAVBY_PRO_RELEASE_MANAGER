import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('combined One Click Release export marks dashboard Export ZIP OK', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<void> _runOneClickReleaseComplete()');
    final end = source.indexOf('Future<bool> _applyReleaseRecipe', start);
    final block = source.substring(start, end);
    final create = block.indexOf('await _createOneClickReleaseZip(');
    final exists = block.indexOf('await combinedReleaseZip.exists()', create);
    final ok = block.indexOf('_dashboardBuildExportOk = true', exists);
    expect(create, greaterThanOrEqualTo(0));
    expect(exists, greaterThan(create));
    expect(ok, greaterThan(exists));
  });
}
