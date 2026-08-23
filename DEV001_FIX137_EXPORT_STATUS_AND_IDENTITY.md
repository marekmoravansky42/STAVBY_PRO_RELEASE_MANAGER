# DEV001 FIX137 – Export status + visible identity

Based on working FIX136.

Observed:
- One Click Release completed successfully.
- Windows and Android artifacts were exported.
- Release Integrity was OK and Publish Gate allowed.
- Dashboard still displayed `Export ZIP – ČAKÁ`.

Cause:
- One Click Release intentionally suppresses the early One Click Build export.
- The later combined Windows+Android export succeeded, but did not set
  `_dashboardBuildExportOk = true`.

Fix:
- Verify the combined ZIP physically exists after export.
- Set Dashboard Export ZIP status to OK only after that verification.
- Set current build step to `Export ZIP OK`.
- Update stale top-right visible identity from FIX126 to FIX137.
- Keep FIX136 fast DEV workflow unchanged.
