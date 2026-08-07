# STAVBY PRO Release Manager 6.1.0 LTS – Build 208

## Modular Core – Phase 1

Build 208 opens the 6.1 modularization cycle while preserving the tested behaviour of Build 206.

### Added

- `lib/core/models/command_result.dart`
  - immutable command result
  - exit status, stdout, stderr and duration
- `lib/core/services/flutter_service.dart`
  - central API for clean, pub get, analyze, test, Windows, APK and AAB builds
- `lib/core/services/logger_service.dart`
  - shared append-only file logging foundation
- `lib/shared/models/progress_step.dart`
  - common pipeline step state for Windows, Android and Release Wizard

### Version

- Application: `6.1.0 LTS Build 208`
- Pubspec: `6.1.0+208`

### Stability policy

The new services are introduced as foundations only. Existing production workflows remain unchanged in this build. Migration from `main.dart` will continue incrementally after successful testing.
