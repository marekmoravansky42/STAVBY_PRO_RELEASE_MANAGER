import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX430 reserves progress space so a standalone Flutter analyze does not move following steps', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('class _ApkWorkflowStep extends StatelessWidget');
    final end = source.indexOf('class _InfoRow extends StatelessWidget', start);

    expect(start, greaterThanOrEqualTo(0));
    final workflowStep = source.substring(start, end);
    expect(workflowStep, contains('if (progress != null)'));
    expect(workflowStep, contains('else\n                  const SizedBox(height: 7)'));
  });
}
