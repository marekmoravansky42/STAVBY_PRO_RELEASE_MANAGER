import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'test_support/nested_flutter_test_lock.dart';

void main() {
  test('actual FINAL dialog scrolls without overflow and closes safely',
      () async {
    final source =
        File('lib/main.dart').readAsStringSync().replaceAll('\r\n', '\n');
    final start = source.indexOf('Future<void> _showFinalPublishCenter(');
    final end =
        source.indexOf('Future<void> _runOneClickReleaseComplete()', start);
    final method = source.substring(start, end);
    final layout = method.substring(method.indexOf('await showDialog<void>('));
    final temp = await Directory.systemTemp.createTemp('fix378_layout_');
    try {
      final file = File(path.join(temp.path, 'layout_test.dart'));
      await file.writeAsString('$_host$layout\n}\n$_tests');
      final configFile = File('.dart_tool/package_config.json').absolute;
      final config = jsonDecode(await configFile.readAsString());
      final flutter = (config['packages'] as List)
          .firstWhere((p) => p['name'] == 'flutter');
      final root = Directory.fromUri(configFile.uri.resolve(flutter['rootUri']))
          .parent
          .parent
          .path;
      final result = await runLockedNestedFlutterTest(
          path.join(root, 'bin', 'cache', 'dart-sdk', 'bin', 'dart.exe'), [
        path.join(root, 'bin', 'cache', 'flutter_tools.snapshot'),
        'test',
        '--no-pub',
        '--timeout',
        '30s',
        file.path
      ]);
      // Preserve measurements in the diagnostic test output.
      stdout.write(result.stdout);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    } finally {
      await temp.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

const _host = r'''
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
class Host extends StatefulWidget {
  const Host({super.key, required this.receipt});
  final bool receipt;
  @override
  State<Host> createState() => HostState();
}
class HostState extends State<Host> {
  dynamic project;
  final releaseZip = File('C:/diagnostic/FINAL_release.zip');
  final notesReady = true, apkReady = false, integrityReady = true, gitReady = false,
      githubReady = false, publishReady = false;
  String? _windowsBuiltExePath;
  final _dashboardReleaseIntegrityStatus = 'INTEGRITY OK';
  dynamic _lastPublicationVerification;
  Map<String, dynamic>? get _lastPersistedFinalPublication => widget.receipt ? {
    'projectName': 'Release Manager', 'projectPath': 'C:/SP/Release_Manager',
    'version': '8.0.0', 'build': 333, 'channel': 'FINAL',
    'timestamp': '2026-09-08T12:00:00', 'apkSha256': 'a' * 64,
    'releaseUrl': 'https://example.invalid/releases/tag/v8.0.0',
    'assetUrl': 'https://example.invalid/releases/download/v8.0.0/app.apk',
  } : null;
  final gitArchive = (localTag: false, remoteTag: false, branchPushed: false,
      tagPointsToHead: false, remoteTagMatchesHead: false, workspaceClean: false,
      tag: 'v8.0.0-final-b333');
  Never _selectFileInExplorer(String _) => throw StateError('Forbidden action');
  Never _showBuildCompletionCenter() => throw StateError('Forbidden action');
  Future<bool> _archiveFinalSourceFromPublishCenter() async => throw StateError('Forbidden action');
  Future<void> _showFinalPublicationHistory() async => throw StateError('Forbidden action');
  Never _openExternalUrl(String _) => throw StateError('Forbidden action');
  void _addLog(String _) {}
  Future<void> _revalidateFinalPublicationOnline() async => throw StateError('Forbidden action');
  Future<void> _publishToGitHub() async => throw StateError('Forbidden action');
  @override
  Widget build(BuildContext context) => Scaffold(body: TextButton(
      onPressed: () => _showFinalPublishCenter(releaseZip: releaseZip), child: const Text('Open')));
  Future<void> _showFinalPublishCenter({required File releaseZip}) async {
''';

const _tests = r'''
void main() {
  for (final scenario in [
    (width: 1200.0, height: 900.0, scale: 1.0, receipt: false),
    (width: 800.0, height: 600.0, scale: 1.0, receipt: false),
    (width: 800.0, height: 600.0, scale: 1.5, receipt: true),
  ]) {
    testWidgets('$scenario', (tester) async {
      await tester.binding.setSurfaceSize(Size(scenario.width, scenario.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scenario.scale)),
          child: child!), home: Host(receipt: scenario.receipt)));
      final errors = <FlutterErrorDetails>[];
      final oldHandler = FlutterError.onError;
      FlutterError.onError = errors.add;
      try {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(errors, isEmpty, reason: errors.map((e) => e.exceptionAsString()).join('\n'));
        expect(find.text('ZAVRIEŤ'), findsOneWidget);
        final scrollable = find.descendant(of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable)).first;
        await tester.scrollUntilVisible(find.text('ZAVRIEŤ'), 200, scrollable: scrollable);
        await tester.pumpAndSettle();
        expect(find.text('ZAVRIEŤ').hitTestable(), findsOneWidget);
        await tester.tap(find.text('ZAVRIEŤ'));
        await tester.pumpAndSettle();
        expect(find.text('FINAL Publish Center'), findsNothing);
        expect(find.text('Open').hitTestable(), findsOneWidget);
        expect(errors, isEmpty, reason: errors.map((e) => e.exceptionAsString()).join('\n'));
      } finally {
        FlutterError.onError = oldHandler;
        await tester.pumpWidget(const SizedBox());
      }
    });
  }

  for (final copy in [
    (
      key: const Key('finalPublishCenterCopyStoredReleaseUrlButton'),
      value: 'https://example.invalid/releases/tag/v8.0.0',
      confirmation: 'Release URL bola skopírovaná do schránky.',
    ),
    (
      key: const Key('finalPublishCenterCopyStoredApkUrlButton'),
      value: 'https://example.invalid/releases/download/v8.0.0/app.apk',
      confirmation: 'APK URL bola skopírovaná do schránky.',
    ),
  ]) {
    testWidgets('stored FINAL URL copy shows its confirmation: ${copy.key}', (tester) async {
      String? clipboardText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: Host(receipt: true)));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final scrollable = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ).first;
      await tester.scrollUntilVisible(find.byKey(copy.key), 200, scrollable: scrollable);
      await tester.tap(find.byKey(copy.key));
      await tester.pump();
      expect(clipboardText, copy.value);
      expect(find.text(copy.confirmation), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
''';
