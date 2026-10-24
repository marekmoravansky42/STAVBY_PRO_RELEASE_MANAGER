import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FIX306 FINAL Publish Center supports explicit online revalidation', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('_revalidateFinalPublicationOnline()'));
    expect(source, contains("Key('finalPublishCenterRevalidateButton')"));
    expect(source, contains("Text('OVERIŤ PUBLIKOVANIE')"));
    expect(source, contains('verifyPublishedRelease('));
    expect(source, contains("updated['lastRevalidatedAt']"));
    expect(source, contains('_updatePersistedFinalPublicationReceipt(updated)'));
  });

  test('FIX306 revalidation does not append duplicate publication audit event', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<bool> _revalidateFinalPublicationOnline()');
    final end = source.indexOf('Future<void> _updatePersistedFinalPublicationReceipt', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final block = source.substring(start, end);
    expect(block, isNot(contains('FINAL_PUBLICATION_ONLINE_VERIFIED')));
  });

  test('FIX440 revalidates inside the open FINAL Publish Center', () {
    final source = File('lib/main.dart').readAsStringSync();
    final button = source.indexOf("Key('finalPublishCenterRevalidateButton')");
    final nextButton = source.indexOf("Key('finalPublishCenterOpenWizardButton')", button);
    expect(button, greaterThanOrEqualTo(0));
    expect(nextButton, greaterThan(button));
    final handler = source.substring(button, nextButton);

    expect(handler, contains('await _revalidateFinalPublicationOnline();'));
    expect(handler, contains('setDialogState(() {});'));
    expect(handler, isNot(contains('Navigator.of(dialogContext).pop();')));
    expect(handler, isNot(contains('await _showFinalPublishCenter(')));
  });
}
