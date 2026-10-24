import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/services/zip_sync_result.dart';

void main() {
  test('successful import is the only result reported as Hotovo', () async {
    var imported = false;
    final result = await selectAndSynchronizeZip(
      selectZip: () async => 'source.zip',
      synchronize: (zip) async {
        expect(zip, 'source.zip');
        imported = true;
        return const ZipSyncResult.success();
      },
    );
    expect(imported, isTrue);
    expect(result.status, ZipSyncStatus.success);
    expect(result.toCompletionStep(), {
      'name': 'Import vývojového ZIPu', 'success': true,
      'skipped': false, 'message': 'Hotovo',
    });
  });

  test('cancelled picker skips import and keeps successful build and next steps', () async {
    final buildStep = <String, Object?>{'name': 'Windows build', 'success': true};
    final steps = [buildStep];
    final result = await selectAndSynchronizeZip(
      selectZip: () async => null,
      synchronize: (_) async => throw StateError('Import must not run'),
    );
    steps.add(result.toCompletionStep());
    steps.add({'name': 'Independent step', 'success': true});
    expect(result.status, ZipSyncStatus.cancelled);
    expect(steps.first, same(buildStep));
    expect(steps.every((s) => s['success'] == true), isTrue);
    expect(steps[1]['skipped'], isTrue);
    expect(steps[1]['message'], 'Preskočené používateľom');
    expect(steps.last['name'], 'Independent step');
  });

  test('internally caught import error remains a failed completion step', () async {
    var errorDialogs = 0;
    final result = await selectAndSynchronizeZip(
      selectZip: () async => 'invalid.zip',
      synchronize: (_) async {
        try {
          throw const FormatException('Invalid source archive');
        } catch (error) {
          errorDialogs++;
          return ZipSyncResult.error(error.toString());
        }
      },
    );
    expect(result.status, ZipSyncStatus.error);
    expect(result.toCompletionStep()['success'], isFalse);
    expect(result.toCompletionStep()['skipped'], isFalse);
    expect(result.message, contains('Invalid source archive'));
    expect(result.message, isNot('Hotovo'));
    expect(errorDialogs, 1);
  });
}
