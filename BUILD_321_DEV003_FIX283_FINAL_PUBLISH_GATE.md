# Build 321 DEV003 FIX283 – FINAL Publish Gate

- FINAL Publish Center now calculates one explicit publish readiness gate.
- Publishing is enabled only when FINAL ZIP exists, APK + SHA-256 are ready, Release Integrity is OK, and Release Notes contain Novinky or Opravy.
- Missing prerequisites keep the publish action disabled and visible as BLOKOVANÉ.
- Existing Release Notes and Git workflow remains unchanged.
