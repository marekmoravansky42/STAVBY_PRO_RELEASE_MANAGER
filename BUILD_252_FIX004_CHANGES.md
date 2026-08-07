# STAVBY PRO Release Manager 7.0.1 LTS – Build 252 FIX004

## Project Workspace – strict platform detection

- Android is supported only when `android/app/build.gradle` or
  `android/app/build.gradle.kts` exists.
- Empty, incomplete, or leftover platform directories no longer enable a
  pipeline build step.
- Windows, Web, Linux, macOS, and iOS detection now also checks their defining
  build/project file instead of only the directory name.
- Unsupported platform steps are resolved by the existing pipeline preflight
  gate and reported as `SKIPPED` before their command is started.
- Added workspace tests for partial Android folders and both Groovy/Kotlin
  Android Gradle layouts.

Build number remains 252 because FIX003 did not complete the full release
pipeline successfully.
