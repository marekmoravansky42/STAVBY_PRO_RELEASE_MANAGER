import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../core/performance/startup_performance.dart';
import 'app_version.dart';

abstract final class AppStartup {
  static void run(Widget app) {
    runZonedGuarded(() {
      WidgetsFlutterBinding.ensureInitialized();
      StartupPerformance.mark('Flutter binding');
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        unawaited(writeCrashLog(
          details.exception,
          details.stack ?? StackTrace.current,
          step: 'Flutter framework',
        ));
      };
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        unawaited(writeCrashLog(
          error,
          stackTrace,
          step: 'Asynchrónna chyba platformy',
        ));
        return true;
      };
      StartupPerformance.mark('pred runApp');
      runApp(app);
    }, (error, stackTrace) {
      unawaited(writeCrashLog(
        error,
        stackTrace,
        step: 'Neobslúžená asynchrónna chyba',
      ));
    });
  }

  static Future<void> writeCrashLog(
    Object error,
    StackTrace stackTrace, {
    String step = 'Neobslúžená chyba aplikácie',
    String? projectPath,
  }) async {
    try {
      final entry = StringBuffer()
        ..writeln('============================================================')
        ..writeln('Dátum: ${DateTime.now().toIso8601String()}')
        ..writeln('Verzia: ${ReleaseManagerVersion.label}')
        ..writeln('Krok: $step')
        ..writeln('Chyba: $error')
        ..writeln('Stack trace:')
        ..writeln(stackTrace)
        ..writeln();

      final logPaths = <String>{
        path.join(
          File(Platform.resolvedExecutable).parent.path,
          'release_manager_crash.log',
        ),
        if (projectPath != null)
          path.join(projectPath, 'release_manager_crash.log'),
      };
      for (final logPath in logPaths) {
        await File(logPath).writeAsString(
          entry.toString(),
          mode: FileMode.append,
          flush: true,
        );
      }
    } catch (_) {
      // Diagnostika nesmie spôsobiť ďalší pád aplikácie.
    }
  }
}
