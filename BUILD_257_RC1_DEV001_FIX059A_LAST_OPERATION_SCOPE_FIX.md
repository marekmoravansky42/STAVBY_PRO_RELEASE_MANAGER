# FIX059A – Last Operation Scope Fix

Fixes the Flutter analyze error introduced in FIX059.

Cause:
`_beginDashboardOperationResult(title)` was accidentally inserted into
`_refreshDashboardStatusWithProgress()`, where `title` does not exist.

Fix:
- refresh uses only the literal `Obnoviť stav`;
- quick Analyze/Test/Windows/Export now calls `_beginDashboardOperationResult(title)`
  in the correct scope, after `title` is resolved;
- FIX059 PREBIEHA -> OK / CHYBA behavior is preserved.
