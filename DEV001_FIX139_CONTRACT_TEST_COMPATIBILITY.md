# DEV001 FIX139 – Contract test compatibility

Flutter test failed because three source-contract tests searched for the exact
pre-FIX138 method/call text. FIX138 intentionally changed:
- `_createOneClickReleaseZip(String projectPath)` to a multiline signature with
  an optional progress callback.
- `await _createOneClickReleaseZip(workspace)` to a multiline call with
  `onProgress`.

The production implementation was not reverted. The tests now search for the
stable method/call prefix, so they validate the same behavior without depending
on formatting or optional named parameters.

Updated tests:
- one_click_release_combined_export_contract_test.dart
- one_click_release_export_status_contract_test.dart
- one_click_release_fail_fast_contract_test.dart

Visible identity: DEV001 FIX139.
