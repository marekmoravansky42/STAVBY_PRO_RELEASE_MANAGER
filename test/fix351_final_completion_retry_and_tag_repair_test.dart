import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();
  final identity = File('lib/app/app_version.dart').readAsStringSync();

  test('FIX351 FINAL tag includes build and matches FINAL Publish Center contract', () {
    expect(File('lib/app/build_completion_tag.dart').readAsStringSync(),
        contains("return 'v\$version-final-b\${identity.build}';"));
    expect(source, contains("final tag = version.isNotEmpty ? 'v\$version-final-b\$build' : '';"));
  });

  test('FIX351 retry skips an already completed commit safely', () {
    expect(source, contains("const <String>['status', '--porcelain']"));
    expect(source, contains('Git commit už bol vykonaný; krok preskakujem.'));
  });

  test('FIX351 existing tag is accepted only when it already points to HEAD', () {
    expect(source, contains("<String>['rev-list', '-n', '1', tagName]"));
    expect(source, contains("const <String>['rev-parse', 'HEAD']"));
    expect(source, contains('už označuje aktuálny commit; krok preskakujem.'));
    expect(source, contains('--is-ancestor'));
    expect(source, contains('FINAL vydanie sa neprepíše'));
  });

  test('FIX351 Release Notes filter historical English technical bullets', () {
    expect(source, contains('String slovakReleaseNoteItem(String item)'));
    expect(source, contains('Zapracované opravy a stabilizačné zmeny aktuálneho buildu.'));
  });

  test('FIX351 canonical identity stays Build 333 DEV015', () {
    expect(identity, contains("static const int build = 333;"));
    expect(identity, contains("static const String stage = 'RC1 DEV015 FIX"));
  });
}
