# FIX061A – Portable Export API Fix

Corrects the three Flutter analyze errors from FIX061:
- uses the project's actual `FilePicker.getDirectoryPath()` API;
- uses `ReleaseManagerVersion.label`;
- uses the existing `_buildDiagnosticReport` + `_saveDiagnosticReport` flow.

The export method was also moved out of the Settings page builder so it is a
proper `_ReleaseManagerPageState` method rather than a local function.
Portable Backup behavior from FIX061 is preserved.
