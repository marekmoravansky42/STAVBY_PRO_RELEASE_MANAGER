# DEV001 FIX152 – Release Dashboard / Integrity source unification

Observed on Build 268:
- Release Dashboard showed 100% and "Posledný release je pripravený".
- Main Dashboard simultaneously showed Release Integrity BLOKOVANÉ.
- Release Dashboard displayed an old BUILD_257 artifact while the active
  Release Manager was Build 268.

Root causes addressed:
1. Distribution Center previously selected candidates primarily by filesystem
   modified time. An older BUILD_257 folder could therefore win over a newer
   BUILD_268 folder if it was touched later.
2. Release Dashboard readiness did not include Release Integrity at all, so it
   could report 100% while Publish Gate was blocked.

FIX152:
- release discovery now prefers the highest BUILD number, with modified time
  only as a tie-breaker,
- Release Dashboard uses the same `_dashboardReleaseIntegrityStatus` and
  `_dashboardPublishGateStatus` as the main Dashboard,
- readiness includes valid Release Integrity,
- Release Dashboard no longer says "release pripravený" when Integrity is
  blocked,
- Release pripravenosť visibly shows Release Integrity and Publish Gate rows.

Identity: 8.0.0 RC1 • Build 269 • DEV001 FIX152.
