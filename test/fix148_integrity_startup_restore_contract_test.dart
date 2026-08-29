import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('integrity restore helper is inside ReleaseManagerPageState', () {
    final source = File('lib/main.dart').readAsStringSync();
    final stateStart = source.indexOf(
      'class _ReleaseManagerPageState extends State<ReleaseManagerPage>',
    );
    final helper = source.indexOf(
      'Future<void> _restoreReleaseIntegrityAfterStartup() async',
    );

    expect(stateStart, greaterThanOrEqualTo(0));
    expect(helper, greaterThan(stateStart));
  });

  test('startup waits for settings before integrity restore', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source,
      contains('_loadAppSettings().whenComplete(()'),
    );
    expect(
      source,
      contains('unawaited(_restoreReleaseIntegrityAfterStartup());'),
    );
    expect(source, contains('!_projectProfilesLoading'));
    expect(source, contains('!_distributionRefreshRunning'));
  });

  test('profile activation refreshes integrity', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<void> _activateProjectProfile');
    final end = source.indexOf('Future<String?> _askProfileName', start);

    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));

    final block = source.substring(start, end);
    expect(block, contains('await _refreshDistributionCenterFromDisk();'));
    expect(
      block,
      contains('await _refreshDashboardReleaseIntegrityStatus(integrityRoot);'),
    );
  });
}
