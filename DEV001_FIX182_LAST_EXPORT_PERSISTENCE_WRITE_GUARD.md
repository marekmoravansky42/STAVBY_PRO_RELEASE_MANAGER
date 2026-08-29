# DEV001 FIX182 – Last Export persistence write guard

Build 299 hardens the persisted Dashboard value `Posledný export ZIP`.

- `_saveLastVerifiedExportZipPath` now catches filesystem/JSON write failures.
- A failed metadata write no longer escapes from the existing `unawaited(...)` call sites as an unhandled async error.
- The successful physical Export ZIP remains authoritative; only the optional Dashboard persistence can fail.
- Failures are recorded in the live log as `Posledný export ZIP sa nepodarilo uložiť: ...`.
- Added a regression contract test for the guarded best-effort persistence behavior.

Identity: Build 299 / DEV001 FIX182.
