# DEV001 FIX151 – Replace stale FIX148 test

The diagnostic confirmed FIX150 runtime source is back on the good FIX147 base.
The remaining analyze errors come only from the old malformed
`test/fix148_integrity_startup_restore_contract_test.dart`.

Workspace Sync SAFE MODE does not delete existing files when a newer ZIP omits
them. FIX150 omitted the bad test, so the old copy survived in C:\SP.

FIX151 includes that exact filename with valid Dart, forcing SAFE MODE to
overwrite the stale copy. Runtime Integrity logic remains the same as FIX150.

Identity: 8.0.0 RC1 • Build 268 • DEV001 FIX151.
