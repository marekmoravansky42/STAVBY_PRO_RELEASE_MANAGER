import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;
  setUpAll(() => source = File('lib/main.dart').readAsStringSync());

  test('FIX224 guards dialog context after async work', () {
    expect(source, contains("if (!mounted) return;\n    final confirmed = await showDialog<bool>("));
  });

  test('FIX225 preserves correct combined ZIP property interpolation', () {
    expect(source, contains("'\${combinedReleaseZip.path}'"));
    expect(source, isNot(contains("'\$combinedReleaseZip.path'")));
  });

  test('FIX226 historical export cleanup test is wording-neutral', () {
    final testSource =
        File('test/fix180_last_export_persistence_contract_test.dart')
            .readAsStringSync();
    expect(testSource, contains('neaktuálne metadata boli odstránené'));
  });

  test('FIX224-227 keeps identity in the canonical version source', () {
    final version = File('lib/app/app_version.dart').readAsStringSync();
    expect(version, contains('abstract final class ReleaseManagerVersion'));
    expect(version, contains('static const int build = '));
    expect(version, contains('static const String stage = '));
  });
}
