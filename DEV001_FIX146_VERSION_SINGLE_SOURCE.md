# DEV001 FIX146 – Version single source

Release Manager identity audit:
- Main badge, diagnostics and core surfaces use `ReleaseManagerVersion`.
- Two stale Plugin Marketplace validators still hardcoded version `6.5.2`.
- Both now use `ReleaseManagerVersion.version`.
- Added a contract test to keep the marketplace tied to the canonical version.
- Canonical identity bumped to Build 263 / DEV001 FIX146.
- pubspec synchronized to `8.0.0+263`.
