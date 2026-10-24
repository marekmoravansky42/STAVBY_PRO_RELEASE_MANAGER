import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/main.dart';

const _longZipName =
    'STAVBY_PRO_RELEASE_MANAGER_8.0.0_RC1_BUILD_333_DEV015_FIX372_ANNOTATED_REMOTE_TAG_PEEL_WINDOWS.zip';
const _overviewValue =
    'Analyze → Test → Windows + Android APK → spoločný ZIP → Integrity → Publish Gate';

Widget dashboardRows({required double textScale, required VoidCallback onTap}) {
  return MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: ReleaseManagerApp(
      loadSavedTheme: false,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const DashboardInfoRow(
                  icon: Icons.rocket_launch_rounded,
                  label: 'One Click Release',
                  value: _overviewValue,
                ),
                const DashboardProjectInfoRow(
                  key: Key('projectInfoShortValueRow'),
                  icon: Icons.numbers_rounded,
                  label: 'Build',
                  value: '333',
                ),
                DashboardProjectInfoRow(
                  key: const Key('projectInfoLongValueRow'),
                  icon: Icons.folder_zip_rounded,
                  label: 'Posledný synchronizovaný ZIP',
                  value: _longZipName,
                ),
                DashboardProjectInfoRow(
                  icon: Icons.archive_outlined,
                  label: 'Posledný export ZIP',
                  value: _longZipName,
                  onTap: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final textScale in <double>[1.0, 1.5]) {
    testWidgets(
        'Dashboard rows keep labels, chevrons, and export action at text scale $textScale',
        (tester) async {
      var exportTapped = false;
      await tester.pumpWidget(
        dashboardRows(
          textScale: textScale,
          onTap: () => exportTapped = true,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Posledný synchronizovaný ZIP'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(3));
      final labelContext =
          tester.element(find.text('Posledný synchronizovaný ZIP'));
      expect(
        MediaQuery.textScalerOf(labelContext).scale(10),
        textScale == 1.0 ? 9 : 13.5,
      );

      await tester.tap(find.text('Posledný export ZIP'));
      await tester.pump();

      expect(exportTapped, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('FIX392 keeps Dashboard labels and values on one line at 100%',
      (tester) async {
    await tester.pumpWidget(
      dashboardRows(textScale: 1.0, onTap: () {}),
    );

    for (final finder in <Finder>[
      find.text('One Click Release'),
      find.text(_overviewValue),
      find.text('Posledný synchronizovaný ZIP'),
      find.text('Posledný export ZIP'),
      find.text(_longZipName),
    ]) {
      for (final text in tester.widgetList<Text>(finder)) {
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('FIX393 aligns short and long project values before chevrons',
      (tester) async {
    await tester.pumpWidget(
      dashboardRows(textScale: 1.0, onTap: () {}),
    );

    final shortValue = find.text('333');
    final longValue = find.text(_longZipName).first;
    final shortChevron = find.descendant(
      of: find.byKey(const Key('projectInfoShortValueRow')),
      matching: find.byIcon(Icons.chevron_right_rounded),
    );
    final longChevron = find.descendant(
      of: find.byKey(const Key('projectInfoLongValueRow')),
      matching: find.byIcon(Icons.chevron_right_rounded),
    );

    final shortText = tester.widget<Text>(shortValue);
    final longText = tester.widget<Text>(longValue);
    expect(shortText.maxLines, 1);
    expect(shortText.overflow, TextOverflow.ellipsis);
    expect(shortText.textAlign, TextAlign.end);
    expect(longText.maxLines, 1);
    expect(longText.overflow, TextOverflow.ellipsis);
    expect(longText.textAlign, TextAlign.end);

    expect(
      tester.getRect(shortValue).right,
      closeTo(tester.getRect(longValue).right, 0.01),
    );
    expect(tester.getRect(shortValue).right, lessThan(tester.getRect(shortChevron).left));
    expect(tester.getRect(longValue).right, lessThan(tester.getRect(longChevron).left));
    expect(tester.takeException(), isNull);
  });
}
