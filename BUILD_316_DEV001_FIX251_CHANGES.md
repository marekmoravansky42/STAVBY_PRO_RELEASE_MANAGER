# Build 316 DEV001 FIX251

Po potvrdení DEV → FINAL preflightu Release Manager vytvorí zálohu konfigurácie do:
`.release_transition_backups/DEV_TO_FINAL_<timestamp>/`

Zálohuje 6 povinných súborov:
- release/stavby_pro_release_profile.json
- lib/core/app/app_identity.dart
- lib/core/app/app_environment.dart
- android/app/build.gradle.kts
- android/app/src/main/AndroidManifest.xml
- pubspec.yaml

Vytvorí aj `transition_backup_manifest.json`.
Ak niektorý súbor chýba, prechod sa zastaví.
FIX251 ešte nevykonáva DEV → FINAL prepis.
