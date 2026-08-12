# FIX072A – Persistent Release Detection

Built from FIX072 Distribution Center v1.

Problem:
Distribution Center used only in-memory paths from the current application
session, so a restart or workspace synchronization made the last release look
empty even though its files still existed on disk.

Fix:
- Distribution Center scans known release roots when the page is opened;
- searches the configured Windows/Android export roots, project parent and
  workspace parent;
- finds the newest valid release directory containing Windows/Android/Update/
  Reports sections;
- restores the Release/FINAL directory path;
- restores the newest EXE/APK/AAB paths found inside that release;
- FINAL directories continue to be marked LTS / FINAL;
- adds `OBNOVIŤ Z DISKU` for manual rescan;
- logs exactly what was recovered.

No release artifacts are moved, deleted or modified by detection.
