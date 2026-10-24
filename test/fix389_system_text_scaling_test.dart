import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/main.dart';

Widget appWithTextScale(double scale) {
  return MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: ReleaseManagerApp(
      loadSavedTheme: false,
      home: Builder(
        builder: (context) => Scaffold(
          body: Text(
            'Scale probe',
            key: const Key('systemTextScaleProbe'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('ReleaseManagerApp keeps enlarged inherited text relative',
      (tester) async {
    await tester.pumpWidget(appWithTextScale(1.5));

    final context =
        tester.element(find.byKey(const Key('systemTextScaleProbe')));
    expect(MediaQuery.textScalerOf(context).scale(10), 13.5);
  });

  testWidgets('ReleaseManagerApp keeps compact baseline at standard text scale',
      (tester) async {
    await tester.pumpWidget(appWithTextScale(1.0));

    final context =
        tester.element(find.byKey(const Key('systemTextScaleProbe')));
    expect(MediaQuery.textScalerOf(context).scale(10), 9);
  });
}
