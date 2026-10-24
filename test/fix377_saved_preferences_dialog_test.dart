import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'test_support/nested_flutter_test_lock.dart';

// Compile the actual private dialog and identity reader into a test-only host.
// This avoids production test hooks and the application's startup side effects.
void main() {
  test('saved FINAL is read from disk when the actual dialog opens', () async {
    final source = File('lib/main.dart').readAsStringSync();
    String method(String start, String end) {
      final offset = source.indexOf(start);
      expect(offset, greaterThanOrEqualTo(0));
      return source.substring(offset, source.indexOf(end, offset));
    }

    final dialog = method('Future<void> _showBuildCompletionCenter()',
        'Future<ProcessResult> _runGitCommand(');
    final identityReader = method(
        'Future<({String version, int build, String stage})?> _readGitBuildIdentity(',
        'ProjectProfile? _projectProfileForWorkspace(');
    final temporary = await Directory.systemTemp.createTemp('fix377_dialog_');
    try {
      final generated = File(path.join(temporary.path, 'dialog_test.dart'));
      await generated.writeAsString(
          _imports + _hostStart + identityReader + dialog + _hostEnd + _tests);
      final configUri = File('.dart_tool/package_config.json').absolute.uri;
      final config = jsonDecode(await File.fromUri(configUri).readAsString());
      final flutter = (config['packages'] as List)
          .firstWhere((entry) => entry['name'] == 'flutter');
      final flutterPackage =
          Directory.fromUri(configUri.resolve(flutter['rootUri']));
      final flutterRoot = flutterPackage.parent.parent.path;
      final result = await runLockedNestedFlutterTest(
        path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin',
            Platform.isWindows ? 'dart.exe' : 'dart'),
        [
          path.join(flutterRoot, 'bin', 'cache', 'flutter_tools.snapshot'),
          'test',
          '--no-pub',
          '--timeout',
          '30s',
          generated.path
        ],
        workingDirectory: Directory.current.path,
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    } finally {
      await temporary.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

const _imports = r'''
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stavby_pro_release_manager/app/build_completion_tag.dart';
import 'package:stavby_pro_release_manager/app/build_completion_validation.dart';
import 'package:stavby_pro_release_manager/app/release_notes_apply_button.dart';
''';

const _hostStart = r'''
class Host extends StatefulWidget {
  const Host({super.key, required this.workspace});
  final String workspace;
  @override
  State<Host> createState() => HostState();
}
class HostState extends State<Host> {
  String? get _gitWorkspacePath => widget.workspace;
  dynamic get _gitWorkspaceStatus => null;
  final _newsController = TextEditingController();
  final _fixesController = TextEditingController();
  String? _releaseNotesPreview;
  void _addLog(String message) {}
  Future<void> _executeBuildCompletion(Map<String, Object?> data) async {
    fail('Build completion must never run in this test');
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: TextButton(
    onPressed: _showBuildCompletionCenter, child: const Text('Open')));
''';

const _hostEnd = r'''
  @override
  void dispose() {
    _newsController.dispose();
    _fixesController.dispose();
    super.dispose();
  }
}
''';

const _tests = r'''
void main() {
  for (final stage in ['DEV015', 'RC1']) {
    testWidgets('saved FINAL opens and reopens with workspace $stage', (tester) async {
      final root = Directory.systemTemp.createTempSync('fix377_workspace_');
      addTearDown(() => root.deleteSync(recursive: true));
      File(path.join(root.path, 'pubspec.yaml')).writeAsStringSync('version: 8.0.0+333\n');
      final identity = File(path.join(root.path, 'lib', 'app', 'app_version.dart'));
      identity.parent.createSync(recursive: true);
      identity.writeAsStringSync("static const String stage = '$stage';");
      final preferences = File(path.join(root.path, '.release_manager', 'build_completion_preferences.json'));
      preferences.parent.createSync(recursive: true);
      final saved = jsonEncode({
        'releaseType': 'FINAL', 'commit': false, 'push': false, 'tag': true,
        'exportZip': false, 'buildReport': false, 'history': false, 'synchronizeZip': false,
      });
      preferences.writeAsStringSync(saved);
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(home: Host(workspace: root.path)));
      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.tap(find.text('Open'));
        await tester.runAsync(() async {
          for (var i = 0; i < 100 && find.byType(AlertDialog).evaluate().isEmpty; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            await tester.pump();
          }
        });
        await tester.pumpAndSettle();
        expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'FINAL')).selected, isTrue);
        final tag = tester.widget<TextField>(find.byWidgetPredicate((w) =>
            w is TextField && w.decoration?.labelText == 'Git tag'));
        expect(tag.controller!.text, 'v8.0.0-final-b333');
        final options = tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile));
        expect(options.length, 7);
        for (final option in options) {
          expect(option.value, (option.title as Text).data == 'Vytvoriť tag');
        }
        await tester.tap(find.text('ZRUŠIŤ'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(await tester.runAsync(() => preferences.readAsString()), saved);
        expect(await tester.runAsync(() => File(path.join(root.path,
            '.release_manager', 'build_completion_draft.json')).exists()), isFalse);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
''';
