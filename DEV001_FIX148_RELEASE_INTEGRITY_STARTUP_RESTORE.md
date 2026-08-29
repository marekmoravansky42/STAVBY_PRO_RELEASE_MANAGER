# DEV001 FIX148 – Release Integrity / Publish Gate startup restore

Problem:
- Dashboard often returned to `NEOVERENÉ` after restarting Release Manager,
  even when the previous release still had a valid 24-hour Publish Gate.
- Startup integrity checks ran concurrently with App Settings / Project Profile
  restoration. The gate is bound to `projectProfileId`, so validation could run
  before `_activeProjectProfileId` was restored.
- The 1-minute timer could also reset the Dashboard while startup discovery was
  still in progress.

Fix:
- Startup integrity restore now runs only after `_loadAppSettings()` completes,
  which includes loading Project Profiles.
- Distribution Center is refreshed first, then the exact persisted release root
  is validated from `RELEASE_INTEGRITY_STATUS.json` + current SHA256 manifest.
- The timer does not reset to `NEOVERENÉ` while settings, profiles, or release
  discovery are still loading.
- Switching/activating a Project Profile now automatically rediscovers the
  release and restores its persisted Integrity/Publish Gate status.
- A valid non-expired gate should therefore return as `INTEGRITY OK` /
  `POVOLENÉ` after restart instead of requiring a manual tab switch.
- Expired, changed, missing, or profile-mismatched gates remain blocked.

Identity: 8.0.0 RC1 • Build 265 • DEV001 FIX148.
