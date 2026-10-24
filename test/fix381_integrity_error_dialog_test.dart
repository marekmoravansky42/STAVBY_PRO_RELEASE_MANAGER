import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'test_support/nested_flutter_test_lock.dart';

void main() {
  test('actual integrity failure: one dialog and blocked publication',
      () async {
    final source =
        File('lib/main.dart').readAsStringSync().replaceAll('\r\n', '\n');
    String slice(String start, String end, [int offset = 0]) {
      final from = source.indexOf(start, offset);
      expect(from, greaterThanOrEqualTo(0));
      return source.substring(from, source.indexOf(end, from));
    }

    final methods = slice('Future<String?> _validateReleasePublishGate(',
        'Widget _buildDistributionCenterPage()');
    final workflow =
        source.indexOf('Future<void> _runOneClickReleaseComplete()');
    final verify = slice(
        'final integrityResult = await _verifyCurrentReleaseIntegrity(',
        "_addLog('ONE CLICK RELEASE: 4/6",
        workflow);
    final catchStart = source.indexOf(
        "} catch (error, stackTrace) {\n      _rememberDashboardOperationResult('One Click Release'",
        workflow);
    expect(catchStart, greaterThanOrEqualTo(0));
    final errorHandler = source.substring(
        catchStart + 2, source.indexOf('} finally {', catchStart));
    final temp = await Directory.systemTemp.createTemp('fix381_test_');
    try {
      final testFile = File(path.join(temp.path, 'integrity_test.dart'));
      await testFile.writeAsString('$_host\n$methods\n'
          'Future<void> automatic() async {\n'
          'final releaseRoot = Directory(widget.root);\n'
          "final selected = 'FINAL'; final workspace = widget.root;\n"
          'try { $verify publicationCalls++; } $errorHandler }\n}\n}\n$_tests');
      final config = File('.dart_tool/package_config.json').absolute;
      final packages =
          jsonDecode(await config.readAsString())['packages'] as List;
      final flutter = packages.firstWhere((p) => p['name'] == 'flutter');
      final root = Directory.fromUri(config.uri.resolve(flutter['rootUri']))
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
        testFile.path
      ]);
      stdout.write(result.stdout);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    } finally {
      await temp.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

const _host = r'''
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
class Counter extends NavigatorObserver {
  int count = 0;
  @override
  void didPush(Route route, Route? previousRoute) { if (route is DialogRoute) count++; }
}
class Host extends StatefulWidget {
  const Host({super.key, required this.root, required this.auto});
  final String root;
  final bool auto;
  @override
  State<Host> createState() => HostState();
}
class HostState extends State<Host> {
  String? get _releaseWizardReleaseDirectory => widget.root;
  String? _activeProjectProfileId;
  String _dashboardReleaseIntegrityStatus = '';
  bool _busy = false, completed = false;
  bool? operationSuccess;
  int publicationCalls = 0, refreshCalls = 0;
  void _addLog(String message) {}
  void _showError(String message) => fail('Unexpected extra notification: $message');
  void _rememberDashboardOperationResult(String name, bool success) => operationSuccess = success;
  Future<void> _writeCrashLog(Object error, StackTrace stackTrace, {required String step, required String projectPath}) async {}
  Future<void> _refreshDashboardReleaseIntegrityStatus(Directory root) async { refreshCalls++; }
  Future<String> _releasePublishGateUiStatus(Directory root) async => 'BLOKOVANÉ';
  void _openDistributionPath(String value) => fail('External operation forbidden');
  @override
  Widget build(BuildContext context) => Scaffold(body: TextButton(
    child: const Text('Run'), onPressed: () async {
      if (widget.auto) { await automatic(); } else { await _verifyCurrentReleaseIntegrity(); }
      completed = true;
    }));
''';

const _tests = r'''
void main() {
  for (final auto in [true, false]) {
    testWidgets(auto ? 'automatic: one outer error' : 'manual: one integrity error', (tester) async {
      final root = Directory.systemTemp.createTempSync('fix381_release_');
      addTearDown(() => root.deleteSync(recursive: true));
      final reports = Directory(path.join(root.path, 'Reports'))..createSync();
      File(path.join(root.path, 'app.bin')).writeAsStringSync('changed payload');
      File(path.join(reports.path, 'SHA256SUMS.txt')).writeAsStringSync('${'0' * 64}  app.bin\n');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final counter = Counter();
      final key = GlobalKey<HostState>();
      await tester.pumpWidget(MaterialApp(navigatorObservers: [counter], home: Host(key: key, root: root.path, auto: auto)));
      await tester.tap(find.text('Run'));
      await tester.runAsync(() async {
        for (var i=0; i<200 && counter.count==0; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();
      expect(counter.count, 1);
      expect(find.text(auto ? 'ONE CLICK RELEASE ZLYHAL' : 'Integrita release nesedí'), findsOneWidget);
      final content = tester.widgetList<SelectableText>(find.byType(SelectableText)).map((w) => w.data ?? '').join('\n');
      expect(content, contains('ZMENENÝ: app.bin'));
      if (auto) expect(content, contains(path.join(reports.path, 'RELEASE_INTEGRITY_REPORT.txt')));
      await tester.tap(find.text(auto ? 'OK' : 'HOTOVO'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        for (var i=0; i<200 && !key.currentState!.completed; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
      });
      expect(key.currentState!.completed, isTrue);
      expect(counter.count, 1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(key.currentState!.publicationCalls, 0);
      expect(key.currentState!.operationSuccess, isFalse);
      if (auto) expect(key.currentState!.refreshCalls, 0);
      final status = jsonDecode(File(path.join(reports.path, 'RELEASE_INTEGRITY_STATUS.json')).readAsStringSync());
      expect(status['publishAllowed'], isFalse);
      expect(status['status'], 'FAILED');
      final blocked = await tester.runAsync(() => key.currentState!._validateReleasePublishGate(root));
      expect(blocked, contains('integrita release neprešla'));
      expect(File(path.join(reports.path, 'RELEASE_INTEGRITY_REPORT.txt')).readAsStringSync(), contains('ZMENENÝ: app.bin'));
      await tester.pumpWidget(const SizedBox());
    });
  }
}
''';
