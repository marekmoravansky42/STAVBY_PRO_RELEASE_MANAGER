import 'dart:io';

import 'package:path/path.dart' as path;

/// Shared logging service used by the modular Release Manager core.
class LoggerService {
  const LoggerService();

  Future<void> write({
    required String fileName,
    required String message,
    String? directory,
  }) async {
    final targetDirectory = directory ?? File(Platform.resolvedExecutable).parent.path;
    final file = File(path.join(targetDirectory, fileName));
    await file.writeAsString(
      message,
      mode: FileMode.append,
      flush: true,
    );
  }

  String timestamp() => DateTime.now().toIso8601String();
}
