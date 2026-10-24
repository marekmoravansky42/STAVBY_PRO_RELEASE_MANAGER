import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/services/final_publication_changelog_service.dart';

void main() {
  test('FIX408 stores, reloads and exposes FINAL Novinky and Opravy', () async {
    final directory = await Directory.systemTemp.createTemp('fix408_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File(
        '${directory.path}${Platform.pathSeparator}final_publications.json');
    final receipt = <String, dynamic>{
      'version': '8.0.0',
      'build': 333,
      'news': normalizeFinalPublicationChangeLog(
          '- Nová funkcia\n\n• Rýchlejší štart'),
      'fixes': normalizeFinalPublicationChangeLog(' - Opravené uloženie '),
    };
    await file.writeAsString(jsonEncode(<Object?>[
      receipt,
      <String, dynamic>{'version': '7.9.0', 'build': 332},
    ]));

    final reloaded = jsonDecode(await file.readAsString()) as List<dynamic>;
    final current = Map<String, dynamic>.from(reloaded.first as Map);
    final legacy = Map<String, dynamic>.from(reloaded.last as Map);

    expect(
      finalPublicationChangeLogSections(current)
          .map((section) => section.title),
      <String>['Novinky', 'Opravy'],
    );
    expect(finalPublicationChangeLogSections(current)[0].items,
        <String>['Nová funkcia', 'Rýchlejší štart']);
    expect(finalPublicationChangeLogSections(current)[1].items,
        <String>['Opravené uloženie']);
    expect(finalPublicationChangeLogSections(legacy), isEmpty);
  });
}
