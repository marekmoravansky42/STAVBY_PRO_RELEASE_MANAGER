# DEV001 FIX135 – Fast DEV One Click Release

Based on the working FIX134.

Optimization:
- DEV One Click Release now uses the existing FAST build pipeline.
- DEV skips `flutter clean` and `flutter pub get`.
- DEV still runs:
  - flutter analyze
  - flutter test
  - Windows Release build
  - Android Release APK build
  - combined Windows + Android export
  - Release Integrity / Publish Gate
- RC and FINAL remain on the safe FULL pipeline with clean + pub get.
- Added phase timing logs and total One Click Release duration so the next
  bottleneck can be measured instead of guessed.
- No change to the working FIX134 export order.
