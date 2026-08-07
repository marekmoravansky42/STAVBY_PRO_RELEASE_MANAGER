# STAVBY PRO Release Manager 6.2.6 LTS – Build 223

## Application lifecycle consolidation – Phase 1

- Added `lib/app/application_controller.dart`.
- Centralized creation and ownership of the Windows, Android, Git, Release Wizard and Diagnostics controllers.
- Replaced five independent controller fields in `main.dart` with access through `ApplicationController`.
- Centralized feature-controller disposal in one idempotent lifecycle method.
- Preserved existing UI, commands and release workflows.
- Updated application version to `6.2.6+223`.
