import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX270 historical identity tests derive pubspec version dynamically', () {
    for (final path in <String>[
      'test/fix264_release_manager_build_identity_sync_test.dart',
      'test/fix265_test_string_escape_fix_test.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('version: 8.0.0+317')));
      expect(source, contains('buildMatch'));
      expect(source, contains('versionMatch'));
    }
  });
}
