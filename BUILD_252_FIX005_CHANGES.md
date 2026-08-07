# STAVBY PRO Release Manager 7.0.1 LTS – Build 252 FIX005

## Project Workspace – analyzer compatibility fix

- Fixed invalid conditional arguments in `path.join(...)` inside
  `ProjectWorkspaceService._hasFile()`.
- Path segments are now assembled explicitly and passed to `path.joinAll()`.
- Fixed workspace tests that incorrectly supplied `recursive` to the
  `Directory` constructor.
- Recursive directory creation now correctly uses `.create(recursive: true)`.
- Strict platform detection and unsupported-step `SKIPPED` behavior from
  FIX004 remain unchanged.

Build number remains 252 because FIX004 did not pass `flutter analyze`.
