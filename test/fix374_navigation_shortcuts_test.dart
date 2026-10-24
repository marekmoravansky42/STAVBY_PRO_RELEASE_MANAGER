import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/app/app_navigation_shortcuts.dart';
import 'package:stavby_pro_release_manager/app/app_version.dart';

const digits = <LogicalKeyboardKey>[
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];

Future<void> pressShortcut(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

Widget harness(List<int> pages, FocusNode focus, {bool textInput = false}) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          AppNavigationShortcuts(
            onSelectPage: pages.add,
            child: const Text('Navigation'),
          ),
          // Deliberately outside the shortcut widget's focus subtree.
          if (textInput)
            TextField(focusNode: focus)
          else
            Focus(focusNode: focus, child: const Text('Other control')),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('all nine shortcuts navigate with focus outside their subtree', (
    tester,
  ) async {
    final pages = <int>[];
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(harness(pages, focus));
    focus.requestFocus();
    await tester.pump();
    for (final digit in digits) {
      await pressShortcut(tester, digit);
    }
    expect(pages, List.generate(9, (index) => index));
    expect(
      ReleaseManagerVersion.badge,
       contains('Build 333 • RC1 DEV015 FIX461'),
    );
    expect(ReleaseManagerVersion.version, '8.0.0');
  });

  testWidgets('text input keeps focus and typing; all shortcuts are ignored', (
    tester,
  ) async {
    final pages = <int>[];
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(harness(pages, focus, textInput: true));
    await tester.enterText(find.byType(TextField), 'rozpracovaný text');
    for (final digit in digits) {
      await pressShortcut(tester, digit);
    }
    expect(pages, isEmpty);
    expect(focus.hasFocus, isTrue);
    expect(find.text('rozpracovaný text'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'rozpracovaný text pokračuje',
    );
    expect(find.text('rozpracovaný text pokračuje'), findsOneWidget);
  });

  testWidgets('dialog blocks navigation, closing it restores shortcuts', (
    tester,
  ) async {
    final pages = <int>[];
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(harness(pages, focus));
    final context = tester.element(find.byType(AppNavigationShortcuts));
    final closed = showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(title: Text('Open dialog')),
    );
    await tester.pumpAndSettle();
    for (final digit in digits) {
      await pressShortcut(tester, digit);
    }
    expect(pages, isEmpty);
    expect(find.text('Open dialog'), findsOneWidget);
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    await closed;
    await pressShortcut(tester, LogicalKeyboardKey.digit9);
    expect(pages, [8]);
  });

  testWidgets('Slovak key, repeats, modifiers and handler disposal', (
    tester,
  ) async {
    final pages = <int>[];
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(harness(pages, focus));
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    expect(pages, isEmpty);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(
      LogicalKeyboardKey.add,
      physicalKey: PhysicalKeyboardKey.digit1,
    );
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyRepeatEvent(
        LogicalKeyboardKey.add,
        physicalKey: PhysicalKeyboardKey.digit1,
      );
    }
    await tester.sendKeyUpEvent(
      LogicalKeyboardKey.add,
      physicalKey: PhysicalKeyboardKey.digit1,
    );
    expect(pages, [0]);
    for (final modifier in [
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.metaLeft,
    ]) {
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(modifier);
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(pages, [0]);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await pressShortcut(tester, LogicalKeyboardKey.digit2);
    expect(pages, [0]);
    expect(tester.takeException(), isNull);
  });
}
