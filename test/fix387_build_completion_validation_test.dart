import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/app/build_completion_validation.dart';

String? validate({
  bool workspaceReady = true,
  bool identityReady = true,
  bool createCommit = false,
  bool createTag = false,
  String commitMessage = '',
  String tagName = '',
}) =>
    validateBuildCompletionInputs(
      workspaceReady: workspaceReady,
      identityReady: identityReady,
      createCommit: createCommit,
      createTag: createTag,
      commitMessage: commitMessage,
      tagName: tagName,
    );

void main() {
  test('report-only completion accepts empty text fields', () {
    expect(validate(), isNull);
  });

  test('history-only completion accepts empty text fields', () {
    expect(validate(), isNull);
  });

  test('commit requires only its message', () {
    expect(validate(createCommit: true), 'Chýba: Commit Message.');
    expect(validate(createCommit: true, commitMessage: 'Dokončenie buildu'),
        isNull);
  });

  test('tag requires only its name', () {
    expect(validate(createTag: true), 'Chýba: názov tagu.');
    expect(validate(createTag: true, tagName: 'v8.0.0-rc-b333'), isNull);
  });

  test('report validation does not require a change description', () {
    expect(validate(commitMessage: '', tagName: ''), isNull);
  });
}
