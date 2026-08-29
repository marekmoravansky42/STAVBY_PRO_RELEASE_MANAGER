# DEV001 FIX165 – One Click Release DEV / RC / FINAL audit

No runtime release behavior is changed in this build.

Added regression tests for the complete mode contract:
- DEV uses the fast build path,
- RC and FINAL use the full build path,
- RC / FINAL always restore the workspace to DEV in `finally`,
- FINAL strips dev/rc suffixes and DEV can restore the dev version form,
- a physical non-empty Export ZIP gate must complete before SHA-256 / Integrity,
- Windows-only projects are not reported as having an Android APK,
- completion remains tied to a physically verified ZIP.

This is the final audit step before manually testing the RC and FINAL modes.

Identity: 8.0.0 RC1 • Build 282 • DEV001 FIX165.
