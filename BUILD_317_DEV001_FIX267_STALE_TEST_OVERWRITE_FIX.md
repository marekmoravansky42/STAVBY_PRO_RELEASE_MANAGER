# Build 317 DEV001 FIX267 – Stale Test Overwrite Fix

Workspace Sync SAFE MODE does not delete files that are absent from an incoming ZIP.
Therefore the malformed historical `test/fix265_test_string_escape_fix_test.dart`
survived FIX266.

FIX267 includes a valid replacement at the exact same path, so SAFE MODE overwrites
the stale file instead of leaving it behind.

Build remains 317. Visible stage advances to RC1 DEV001 FIX267.
