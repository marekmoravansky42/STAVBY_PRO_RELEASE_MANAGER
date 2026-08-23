# DEV001 FIX134 – One Click Release Continuous Workflow

Observed:
- ONE CLICK RELEASE embedded the normal FULL BUILD.
- FULL BUILD showed its own success dialog after Windows build.
- The user therefore saw `FULL BUILD successful` while the One Click Release
  workflow was still active and Android/export had not yet run.
- Export ZIP correctly showed WAITING, which made the workflow look stuck.

Fix:
- `_runOneClickBuild` now supports `showCompletionDialog`.
- Standalone FAST/FULL BUILD keeps the existing completion dialog by default.
- ONE CLICK RELEASE calls FULL BUILD with:
  - `exportReleaseZip: false`
  - `showCompletionDialog: false`
- ONE CLICK RELEASE now continues automatically:
  Analyze/Test/Windows -> Android APK -> combined Windows+Android ZIP ->
  Integrity/Publish Gate -> final One Click Release dialog.
- No intermediate FULL BUILD modal interrupts the release pipeline.
- FIX127–FIX133 remain included.
