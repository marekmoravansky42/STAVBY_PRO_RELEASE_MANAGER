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

void main() {
  test('FIX397 SHA-256 history callback respects its dialog context', () async {
    final source =
        File('lib/main.dart').readAsStringSync().replaceAll('\r\n', '\n');
    final marker = source.indexOf('onPressed: apkSha256.isEmpty');
    expect(marker, greaterThanOrEqualTo(0));
    final openingBrace = source.indexOf('{', marker);
    final closingBrace = _matchingBrace(source, openingBrace);
    expect(closingBrace, greaterThan(openingBrace));
    final callbackBody = source.substring(openingBrace + 1, closingBrace);

    final temp = await Directory.systemTemp.createTemp('fix397_history_');
    try {
      final file = File(path.join(temp.path, 'sha256_history_test.dart'));
      await file
          .writeAsString('$_hostStart\n$callbackBody\n$_hostEnd\n$_tests');
      final configFile = File('.dart_tool/package_config.json').absolute;
      final config = jsonDecode(await configFile.readAsString());
      final flutter = (config['packages'] as List)
          .firstWhere((entry) => entry['name'] == 'flutter');
      final root = Directory.fromUri(configFile.uri.resolve(flutter['rootUri']))
          .parent
          .parent
          .path;
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
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    } finally {
      await temp.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

const _hostStart = r'''
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class Host extends StatelessWidget {
  const Host({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            content: Builder(
              builder: (context) {
                const apkSha256 = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
                return TextButton.icon(
                  onPressed: apkSha256.isEmpty
                      ? null
                      : () async {
''';

const _hostEnd = r'''
                      },
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('SHA-256'),
                );
              },
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('ZAVRIEŤ'),
              ),
            ],
          ),
        ),
        child: const Text('OTVORIŤ'),
      ),
    ),
  );
}
''';

const _tests = r'''
void main() {
  testWidgets('closed dialog never receives a late SHA-256 SnackBar', (tester) async {
    final copied = Completer<void>();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) => call.method == 'Clipboard.setData' ? copied.future : Future.value(),
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(const MaterialApp(home: Host()));
    await tester.tap(find.text('OTVORIŤ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SHA-256'));
    await tester.pump();
    await tester.tap(find.text('ZAVRIEŤ'));
    await tester.pumpAndSettle();
    copied.complete();
    await tester.pumpAndSettle();
    expect(find.text('SHA-256 bol skopírovaný do schránky.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('open dialog keeps the SHA-256 confirmation', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(const MaterialApp(home: Host()));
    await tester.tap(find.text('OTVORIŤ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SHA-256'));
    await tester.pumpAndSettle();
    expect(find.text('SHA-256 bol skopírovaný do schránky.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
''';
