# Build 317 DEV001 FIX265 – Test String Escape Fix

FIX264 production build identity sync remains unchanged.

FIX265 fixes only the regression test:
- expected source lines use raw strings,
- `$version`, `$channel`, `$build`, and `$stage` are checked literally,
- Release Manager remains on Build 317,
- stage advances to RC1 DEV001 FIX265.
