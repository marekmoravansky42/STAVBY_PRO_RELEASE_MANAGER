import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class TestPluginGenerationRequest {
  const TestPluginGenerationRequest({
    required this.parentDirectory,
    required this.pluginId,
    required this.pluginName,
    this.author = 'Marek',
    this.version = '1.0.0',
    this.apiVersion = '1.0.0',
  });

  final Directory parentDirectory;
  final String pluginId;
  final String pluginName;
  final String author;
  final String version;
  final String apiVersion;
}

class TestPluginGenerationResult {
  const TestPluginGenerationResult._({
    required this.success,
    required this.message,
    this.pluginDirectory,
  });

  factory TestPluginGenerationResult.success(Directory pluginDirectory) {
    return TestPluginGenerationResult._(
      success: true,
      message: 'Testovací plugin bol úspešne vytvorený.',
      pluginDirectory: pluginDirectory,
    );
  }

  factory TestPluginGenerationResult.failure(String message) {
    return TestPluginGenerationResult._(
      success: false,
      message: message,
    );
  }

  final bool success;
  final String message;
  final Directory? pluginDirectory;
}

/// Creates a safe, minimal plugin package that can be used to test the local
/// installation flow. It generates source files only; no foreign code is run.
class TestPluginGenerator {
  const TestPluginGenerator();

  Future<TestPluginGenerationResult> generate(
    TestPluginGenerationRequest request,
  ) async {
    final pluginId = request.pluginId.trim();
    final pluginName = request.pluginName.trim();
    final author = request.author.trim();

    if (!_isValidPluginId(pluginId)) {
      return TestPluginGenerationResult.failure(
        'ID pluginu môže obsahovať iba malé písmená, čísla, bodky, pomlčky a podčiarkovníky.',
      );
    }
    if (pluginName.isEmpty) {
      return TestPluginGenerationResult.failure(
        'Názov pluginu nesmie byť prázdny.',
      );
    }
    if (!_isSemanticVersion(request.version)) {
      return TestPluginGenerationResult.failure(
        'Verzia pluginu musí byť v tvare napríklad 1.0.0.',
      );
    }
    if (!_isSemanticVersion(request.apiVersion)) {
      return TestPluginGenerationResult.failure(
        'Verzia Plugin API musí byť v tvare napríklad 1.0.0.',
      );
    }

    try {
      await request.parentDirectory.create(recursive: true);
      final pluginDirectory = Directory(
        p.join(request.parentDirectory.path, pluginId),
      );
      if (await pluginDirectory.exists()) {
        return TestPluginGenerationResult.failure(
          'Cieľový priečinok už existuje: ${pluginDirectory.path}',
        );
      }

      final libDirectory = Directory(p.join(pluginDirectory.path, 'lib'));
      final testDirectory = Directory(p.join(pluginDirectory.path, 'test'));
      final assetsDirectory = Directory(p.join(pluginDirectory.path, 'assets'));
      await libDirectory.create(recursive: true);
      await testDirectory.create(recursive: true);
      await assetsDirectory.create(recursive: true);

      final manifest = <String, Object>{
        'id': pluginId,
        'name': pluginName,
        'version': request.version,
        'apiVersion': request.apiVersion,
        'enabled': true,
        'description': 'Testovací plugin vytvorený v STAVBY PRO Release Manageri.',
        'entryPoint': 'lib/plugin.dart',
        'capabilities': <String>['diagnosticsProvider'],
        'permissions': <String>['diagnostics'],
        'author': author.isEmpty ? 'Marek' : author,
      };

      await File(p.join(pluginDirectory.path, 'plugin.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert(manifest),
        flush: true,
      );
      await File(p.join(libDirectory.path, 'plugin.dart')).writeAsString(
        _pluginSource(pluginName),
        flush: true,
      );
      await File(p.join(testDirectory.path, 'plugin_test.dart')).writeAsString(
        _testSource(pluginName),
        flush: true,
      );
      await File(p.join(pluginDirectory.path, 'README.md')).writeAsString(
        '# $pluginName\n\n'
        'Testovací plugin vytvorený pomocou STAVBY PRO Release Managera.\n\n'
        '## Inštalácia\n\n'
        'V sekcii **Pluginy** vyber zodpovedajúci plugin z demo katalógu, '
        'klikni na **Inštalovať z priečinka** a vyber tento priečinok.\n',
        flush: true,
      );
      await File(p.join(pluginDirectory.path, 'CHANGELOG.md')).writeAsString(
        '# Changelog\n\n## ${request.version}\n\n- Vytvorený testovací plugin.\n',
        flush: true,
      );
      await File(p.join(pluginDirectory.path, 'LICENSE')).writeAsString(
        'Testovací plugin určený iba na interné testovanie.\n',
        flush: true,
      );

      return TestPluginGenerationResult.success(pluginDirectory);
    } on FileSystemException catch (error) {
      return TestPluginGenerationResult.failure(
        'Plugin sa nepodarilo vytvoriť: ${error.message}',
      );
    }
  }

  bool _isValidPluginId(String value) {
    return RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(value);
  }

  bool _isSemanticVersion(String value) {
    return RegExp(r'^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$')
        .hasMatch(value.trim());
  }

  String _pluginSource(String pluginName) => '''
/// Minimal test plugin generated by STAVBY PRO Release Manager.
class TestPlugin {
  const TestPlugin();

  String get name => ${jsonEncode(pluginName)};

  String runDiagnostic() => 'Hello from \$name';
}
''';

  String _testSource(String pluginName) => '''
import '../lib/plugin.dart';

void main() {
  const plugin = TestPlugin();
  assert(plugin.name == ${jsonEncode(pluginName)});
}
''';
}
