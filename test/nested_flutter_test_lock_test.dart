import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'test_support/nested_flutter_test_lock.dart';

void main() {
  test('serializes concurrent nested Flutter test lock holders', () async {
    final temporary =
        await Directory.systemTemp.createTemp('nested_flutter_lock_');
    final lockFile = File(path.join(temporary.path, 'nested.lock'));
    final first = await NestedFlutterTestLock.acquire(lockFile: lockFile);
    var secondEntered = false;
    final secondFuture =
        NestedFlutterTestLock.acquire(lockFile: lockFile).then((lock) {
      secondEntered = true;
      return lock;
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(secondEntered, isFalse);
      await first.release();
      final second = await secondFuture;
      try {
        expect(secondEntered, isTrue);
      } finally {
        await second.release();
      }
    } finally {
      await first.release();
      await temporary.delete(recursive: true);
    }
  });
}
