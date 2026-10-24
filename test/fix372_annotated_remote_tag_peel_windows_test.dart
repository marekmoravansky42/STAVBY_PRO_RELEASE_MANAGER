import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX372 keeps remote annotated tag peel argument away from cmd caret parsing', () {
    final source = File('lib/main.dart').readAsStringSync();
    final verifyStart = source.indexOf('_verifyFinalSourceArchive');
    final verifyEnd = source.indexOf('_archiveFinalSourceFromPublishCenter', verifyStart);
    final verifySource = source.substring(verifyStart, verifyEnd);
    expect(verifySource, contains("'refs/tags/\$tag^{}'"));
    expect(verifySource, contains('runInShell: false'));
  });
}
