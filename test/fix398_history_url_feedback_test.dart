import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'test_support/nested_flutter_test_lock.dart';

int _matchingBrace(String source, int openingBrace) {
  var depth = 0;
  for (var index = openingBrace; index < source.length; index++) {
    final character = source[index];
    if (character == '{') depth++;
    if (character == '}' && --depth == 0) return index;
  }
  return -1;
}

String _callbackBody(String source, String marker) {
  final markerIndex = source.indexOf(marker);
  expect(markerIndex, greaterThanOrEqualTo(0));
  final openingBrace = source.indexOf('{', markerIndex);
  final closingBrace = _matchingBrace(source, openingBrace);
  expect(closingBrace, greaterThan(openingBrace));
  return source.substring(openingBrace + 1, closingBrace);
}

void main() {
  test(
    'FIX398 history URL callbacks provide safe copy feedback',
    () async {
      final source = File(
        'lib/main.dart',
      ).readAsStringSync().replaceAll('\r\n', '\n');
      final release = _callbackBody(source, 'onPressed: releaseUrl.isEmpty');
      final apk = _callbackBody(source, 'onPressed: assetUrl.isEmpty');
      final temp = await Directory.systemTemp.createTemp('fix398_history_');
      try {
        final file = File(path.join(temp.path, 'history_url_test.dart'));
        await file.writeAsString(
          '$_hostStart\n$release\n$_between\n$apk\n$_hostEnd\n$_tests',
        );
        final configFile = File('.dart_tool/package_config.json').absolute;
        final config = jsonDecode(await configFile.readAsString());
        final flutter = (config['packages'] as List).firstWhere(
          (entry) => entry['name'] == 'flutter',
        );
        final root = Directory.fromUri(
          configFile.uri.resolve(flutter['rootUri']),
        ).parent.parent.path;
        final result = await runLockedNestedFlutterTest(
          path.join(root, 'bin', 'cache', 'dart-sdk', 'bin', 'dart.exe'),
          <String>[
            path.join(root, 'bin', 'cache', 'flutter_tools.snapshot'),
            'test',
            '--no-pub',
            '--timeout',
            '30s',
            file.path,
          ],
        );
        stdout.write(result.stdout);
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
      } finally {
        await temp.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

const _hostStart = r'''
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
class Host extends StatelessWidget {
  const Host({super.key});
  @override
  Widget build(BuildContext outerContext) => Scaffold(body: Center(child: TextButton(
    onPressed: () => showDialog<void>(context: outerContext, builder: (dialogContext) => AlertDialog(
      content: Builder(builder: (context) {
        const releaseUrl = 'https://example.invalid/release';
        const assetUrl = 'https://example.invalid/app.apk';
        return Wrap(children: <Widget>[
          TextButton(onPressed: () async {
''';

const _between = r'''
          }, child: const Text('RELEASE URL')),
          TextButton(onPressed: () async {
''';

const _hostEnd = r'''
          }, child: const Text('APK URL')),
        ]);
      }),
      actions: <Widget>[TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('ZAVRIEŤ'))],
    )), child: const Text('OTVORIŤ'))));
}
''';

const _tests = r'''
void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Host()));
    await tester.tap(find.text('OTVORIŤ'));
    await tester.pumpAndSettle();
  }
  for (final item in [
    ('RELEASE URL', 'https://example.invalid/release', 'Release URL bola skopírovaná do schránky.'),
    ('APK URL', 'https://example.invalid/app.apk', 'APK URL bola skopírovaná do schránky.'),
  ]) {
    testWidgets('open dialog copies and confirms ${item.$1}', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
        }
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await open(tester);
      await tester.tap(find.text(item.$1));
      await tester.pumpAndSettle();
      expect(copied, item.$2);
      expect(find.text(item.$3), findsOneWidget);
    });
  }
  testWidgets('closed dialog has no late URL SnackBar or exception', (tester) async {
    final copied = Completer<void>();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) => copied.future);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await open(tester);
    await tester.tap(find.text('RELEASE URL'));
    await tester.pump();
    await tester.tap(find.text('ZAVRIEŤ'));
    await tester.pumpAndSettle();
    copied.complete();
    await tester.pumpAndSettle();
    expect(find.text('Release URL bola skopírovaná do schránky.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
''';
