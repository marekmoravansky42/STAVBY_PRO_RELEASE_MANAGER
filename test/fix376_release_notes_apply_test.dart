import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/app/release_notes_apply_button.dart';

void main() {
  for (final newsOnly in [true, false]) {
    testWidgets(
        'empty proposals preserve notes; applies ${newsOnly ? 'news' : 'fixes'} only',
        (tester) async {
      final news = TextEditingController();
      final fixes = TextEditingController();
      final targetNews = TextEditingController(text: 'Existing news');
      final targetFixes = TextEditingController(text: 'Existing fixes');
      String? preview = 'Existing Markdown';
      var successCount = 0;
      addTearDown(() {
        news.dispose();
        fixes.dispose();
        targetNews.dispose();
        targetFixes.dispose();
      });
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  content: ReleaseNotesApplyButton(
                    news: news,
                    fixes: fixes,
                    onApply: () {
                      targetNews.text = news.text;
                      targetFixes.text = fixes.text;
                      preview = null;
                      successCount++;
                    },
                  ),
                ),
              ),
              child: const Text('Open'),
            );
          }),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      const warning =
          'Návrh je prázdny. Najprv načítajte históriu alebo zadajte novinky či opravy.';
      for (final empty in ['', ' \t\n\r ']) {
        news.text = empty;
        fixes.text = empty;
        await tester.tap(find.text('POUŽIŤ PRE RELEASE NOTES'));
        await tester.pump();
        expect(targetNews.text, 'Existing news');
        expect(targetFixes.text, 'Existing fixes');
        expect(preview, 'Existing Markdown');
        expect(successCount, 0);
        expect(
            find.descendant(
                of: find.byType(AlertDialog), matching: find.text(warning)),
            findsOneWidget);
      }
      news.text = newsOnly ? ' New news ' : '';
      fixes.text = newsOnly ? '' : ' New fix ';
      await tester.tap(find.text('POUŽIŤ PRE RELEASE NOTES'));
      await tester.pump();
      expect(targetNews.text, news.text);
      expect(targetFixes.text, fixes.text);
      expect(preview, isNull);
      expect(successCount, 1);
      expect(find.text(warning), findsNothing);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
