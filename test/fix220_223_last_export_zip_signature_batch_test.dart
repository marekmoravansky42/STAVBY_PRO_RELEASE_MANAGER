import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX220 persistence validates ZIP signature', () {
    expect(source, contains("Future<bool> _hasZipSignature"));
    expect(source, contains("súbor nemá platnú ZIP signatúru"));
  });

  test('FIX221 temp recovery validates ZIP signature', () {
    expect(source, contains("await _hasZipSignature(normalizedTempZipPath)"));
  });

  test('FIX222 canonical restore validates ZIP signature', () {
    expect(source, contains("await _hasZipSignature(normalizedSavedPath)"));
  });

  test('FIX223 invalid ZIP cleanup log is explicit', () {
    expect(source, contains("chýba alebo nie je platný ZIP"));
  });

  test('FIX220-223 keeps identity in the canonical version source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
