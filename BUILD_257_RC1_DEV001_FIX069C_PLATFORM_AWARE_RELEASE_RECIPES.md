# FIX069C – Platform Aware Release Recipes

Built from FIX069B after RC reached the Android build step.

Problem found in real RC test:
Release Manager itself is a valid Windows project but does not contain a
complete Android app (`android/app/build.gradle` / `.kts` + manifest).
RC/LTS still forced APK and AAB and therefore failed.

Fix:
- Release Wizard detects actual project capabilities before starting.
- Windows is built only when a valid Windows Flutter platform exists.
- Android APK/AAB are built only when a complete Android app platform exists.
- Android detection supports both `build.gradle` and `build.gradle.kts`.
- Missing platforms are explicitly logged as PRESKOČENÉ, not reported as a
  build failure.
- Release package and final status describe the actual built platforms.

Expected Release Manager RC:
clean -> pub get -> analyze -> test -> Windows -> release package
(Android safely skipped).

Expected STAVBY PRO RC/LTS:
Windows + APK + AAB remain enabled when the Android platform is complete.
