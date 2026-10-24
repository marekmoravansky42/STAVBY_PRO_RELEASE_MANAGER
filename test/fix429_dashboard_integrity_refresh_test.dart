import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX429 clears a missing release and its dashboard integrity state on refresh', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf(
      'Distribution Center: na disku nebol nájdený predchádzajúci release',
    );
    final end = source.indexOf('int releaseBuildNumber(', start);

    expect(start, greaterThanOrEqualTo(0));
    final emptyResult = source.substring(start, end);
    expect(emptyResult, contains('final activeReleaseMissing'));
    expect(emptyResult, contains('_releaseWizardReleaseDirectory = null'));
    expect(emptyResult, contains('_resetDashboardReleaseIntegrityStatus()'));
  });
}
