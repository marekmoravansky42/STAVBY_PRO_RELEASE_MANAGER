import 'dart:io';

import '../models/command_result.dart';
import '../services/flutter_service.dart';
import '../services/plugin_service.dart';
import 'automated_test.dart';

class DefaultTestSuite {
  const DefaultTestSuite({
    this.flutterService = const FlutterService(),
    this.pluginService = const PluginService(
      releaseManagerVersion: '6.1.6',
    ),
  });

  final FlutterService flutterService;
  final PluginService pluginService;

  List<AutomatedTestDefinition> create({
    required String projectPath,
    required String exportPath,
    required bool windowsEnabled,
    required bool androidEnabled,
  }) => <AutomatedTestDefinition>[
        AutomatedTestDefinition(
          id: 'project_validation',
          title: 'Project Validation',
          execute: () async {
            final pubspec = File('$projectPath${Platform.pathSeparator}pubspec.yaml');
            if (!await pubspec.exists()) {
              throw const AutomatedTestFailure('pubspec.yaml nebol nájdený.');
            }
            return 'Projektový adresár je platný.';
          },
        ),
        AutomatedTestDefinition(
          id: 'flutter_analyze',
          title: 'Flutter Analyze',
          execute: () async => _requireSuccess(await flutterService.analyze(projectPath)),
        ),
        AutomatedTestDefinition(
          id: 'dart_format',
          title: 'Dart Format Check',
          execute: () async {
            final result = await Process.run(
              'dart',
              const <String>['format', '--output=none', '--set-exit-if-changed', '.'],
              workingDirectory: projectPath,
              runInShell: true,
            );
            if (result.exitCode != 0) {
              throw AutomatedTestFailure(_combinedOutput(result.stdout, result.stderr));
            }
            return _combinedOutput(result.stdout, result.stderr);
          },
        ),
        AutomatedTestDefinition(
          id: 'windows_build',
          title: 'Windows Release Build',
          enabled: windowsEnabled,
          execute: () async => _requireSuccess(await flutterService.buildWindows(projectPath)),
        ),
        AutomatedTestDefinition(
          id: 'android_apk',
          title: 'Android APK Build',
          enabled: androidEnabled,
          execute: () async => _requireSuccess(await flutterService.buildApk(projectPath)),
        ),
        AutomatedTestDefinition(
          id: 'android_aab',
          title: 'Android AAB Build',
          enabled: androidEnabled,
          execute: () async => _requireSuccess(await flutterService.buildAppBundle(projectPath)),
        ),
        AutomatedTestDefinition(
          id: 'plugin_validation',
          title: 'Plugin Validation',
          execute: () async {
            final registrations = await pluginService.discover(
              '$projectPath${Platform.pathSeparator}plugins',
            );
            final invalid = registrations.where((item) => !item.isReady).toList();
            if (invalid.isNotEmpty) {
              throw AutomatedTestFailure(
                invalid.map((item) => '${item.manifest?.name ?? item.manifestPath}: ${item.message}').join('\n'),
              );
            }
            return '${registrations.length} pluginov overených.';
          },
        ),
        AutomatedTestDefinition(
          id: 'export_validation',
          title: 'Export Validation',
          execute: () async {
            final directory = Directory(exportPath);
            await directory.create(recursive: true);
            final probe = File('${directory.path}${Platform.pathSeparator}.quality_gate_probe');
            await probe.writeAsString('ok');
            await probe.delete();
            return 'Exportný adresár je zapisovateľný.';
          },
        ),
      ];

  String? _requireSuccess(CommandResult result) {
    if (!result.succeeded) {
      throw AutomatedTestFailure(
        '${result.executable} ${result.arguments.join(' ')}\n${_commandOutput(result)}',
      );
    }
    return _commandOutput(result);
  }

  String _commandOutput(CommandResult result) =>
      '${result.standardOutput}\n${result.standardError}'.trim();

  String _combinedOutput(Object? stdout, Object? stderr) =>
      '${stdout ?? ''}\n${stderr ?? ''}'.trim();
}
