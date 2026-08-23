# DEV001 FIX129 – One Click Release Android APK

Problem:
- ONE CLICK RELEASE ran analyze, test and Windows Release build, but never invoked
  `flutter build apk --release`, so no Android APK was created.

Fix:
- Detects Android support from the target project's `android/` directory.
- Runs `flutter build apk --release` as step 3 of ONE CLICK RELEASE.
- Fails the release if the Android build fails or no release APK is found.
- Calculates APK size and SHA-256 and updates APK Manager state.
- If Android Release export directory is configured, copies the APK there using
  the project's release filename.
- If no Android export directory is configured, keeps the generated APK in
  `build/app/outputs/flutter-apk/app-release.apk` and logs the location.
- Projects without Android skip the APK step cleanly.
- Pipeline progress changed from 5 to 6 stages.
- DEV / RC / FINAL selector from FIX128 and SemVer parser from FIX127 remain included.
- Release Manager remains 8.0.0 RC1 Build 257; this is DEV001 FIX129.
