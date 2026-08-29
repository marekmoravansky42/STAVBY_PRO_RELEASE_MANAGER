# Build 316 DEV001 FIX256

Test-maintenance only.

Updated stale regression tests that still expected a hard-coded DEV export
stage everywhere or the old FIX253 identity.

Current contract:
- FAST DEV / standalone export may remain DEV.
- Controlled FINAL FULL BUILD may use a dynamic FINAL release stage.
- Production Release Manager identity remains RC1 DEV001 FIX254.
- No production FINAL workflow code changed in FIX256.
