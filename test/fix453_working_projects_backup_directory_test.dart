import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final mainSource = File('lib/main.dart').readAsStringSync();
  final settingsSource =
      File('lib/services/app_settings_service.dart').readAsStringSync();

  test('FIX453 stores working backups separately and shows their progress', () {
    expect(
      settingsSource,
      contains('workingProjectsBackupDirectory'),
    );
    expect(
      mainSource,
      contains("'Working Project Backups'"),
    );
    expect(
      mainSource,
      contains('_workingProjectsBackupDirectory'),
    );
    expect(
      mainSource,
      contains('Vytváram pracovnú zálohu'),
    );
    expect(mainSource, contains('Kopírujem aktuálne zdroje STAVBY PRO'));
    expect(mainSource, contains('Vytváram komprimovaný ZIP archív'));
  });
}
