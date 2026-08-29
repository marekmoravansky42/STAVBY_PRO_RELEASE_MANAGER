# DEV001 FIX171 – Low-risk analyzer cleanup

After the functional export/release fixes were stabilized, this build removes
three obsolete warnings without changing runtime behavior:

- unused Git build identity read in `_createOneClickReleaseZip`,
- unused `_dashboardEventRow` helper left over after the Last Events card was removed,
- unused `apkReady` local in the Dashboard overview.

No release, export, Integrity, Publish Gate or UI workflow logic is changed.

Identity: Build 288 / DEV001 FIX171.
