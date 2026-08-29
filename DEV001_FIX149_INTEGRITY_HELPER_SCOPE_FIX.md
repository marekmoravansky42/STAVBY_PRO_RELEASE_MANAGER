# DEV001 FIX149 – Integrity startup helper scope fix

The FIX148 helper was inserted before the first `dispose()` in main.dart, which
belongs to `_PreflightDialogState`, not `_ReleaseManagerPageState`. Therefore
Flutter analyze correctly reported undefined Release Manager methods/fields in
Preflight and the helper was unavailable where startup called it.

FIX149:
- moves `_restoreReleaseIntegrityAfterStartup()` into `_ReleaseManagerPageState`,
- preserves FIX148 startup ordering and timer protection,
- removes now-unused `_dashboardEventRow` after the Last Events card removal,
- removes the unused `apkReady` local left by Dashboard cleanup,
- adds a contract check that the integrity helper can never be placed before
  `_ReleaseManagerPageState` again.

Identity: 8.0.0 RC1 • Build 266 • DEV001 FIX149.
