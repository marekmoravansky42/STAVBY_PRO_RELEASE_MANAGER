# Build 318 DEV001 FIX270

- Keeps FIX268 FAST DEV Android APK parity.
- Keeps Release Manager on Build 318.
- Removes the final two stale hard-coded `version: 8.0.0+317` expectations from historical identity tests.
- Historical tests now derive version/build from canonical `ReleaseManagerVersion` and compare pubspec dynamically.
