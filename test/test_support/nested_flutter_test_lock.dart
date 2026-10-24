import 'dart:io';

import 'package:path/path.dart' as path;

/// Serializes only the nested Flutter tools that use this project's build tree.
///
/// The operating-system file lock is released if its owning process exits, so a
/// leftover lock *file* after a crash never blocks the next test run.
final class NestedFlutterTestLock {
  NestedFlutterTestLock._(this._handle);

  final RandomAccessFile _handle;
  var _released = false;

  static Future<NestedFlutterTestLock> acquire({File? lockFile}) async {
    final file = lockFile ??
        File(path.join(
          Directory.current.path,
          '.dart_tool',
          'release_manager_nested_flutter_test.lock',
        ));
    await file.parent.create(recursive: true);
    final deadline = DateTime.timestamp().add(const Duration(minutes: 1));
    while (true) {
      final handle = await file.open(mode: FileMode.append);
      try {
        await handle.lock(FileLock.exclusive);
        return NestedFlutterTestLock._(handle);
      } on FileSystemException {
        await handle.close();
        if (DateTime.timestamp().isAfter(deadline)) {
          throw StateError('Timed out waiting for nested Flutter test lock: '
              '${file.path}');
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      } catch (_) {
        await handle.close();
        rethrow;
      }
    }
  }

  Future<void> release() async {
    if (_released) return;
    _released = true;
    try {
      await _handle.unlock();
    } finally {
      await _handle.close();
    }
  }
}

Future<ProcessResult> runLockedNestedFlutterTest(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  final lock = await NestedFlutterTestLock.acquire();
  try {
    return await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );
  } finally {
    await lock.release();
  }
}
