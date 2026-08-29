# DEV001 FIX179 – FIX178 format-independent test

The Build 295 runtime behavior is correct. FIX178 failed because its new
regression test searched for one exact single-line Dart source fragment, while
the existing manual Explorer call is formatted over multiple lines.

FIX179 makes that structural test formatting-independent:
- `_selectFileInExplorer(` must exist,
- `_dashboardLastVerifiedExportZipPath!` must exist,
- FAST DEV automatic Explorer opening must still be absent.

No runtime behavior is changed.

Identity: Build 296 / DEV001 FIX179.
