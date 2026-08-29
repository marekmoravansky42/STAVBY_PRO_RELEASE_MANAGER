# DEV001 FIX180 – Persist Last Export ZIP

The Dashboard now remembers `Posledný export ZIP` across Release Manager
restarts and project refreshes.

- the exact verified ZIP path is stored in
  `<workspace>/.release_manager/last_export.json`,
- the path is restored when the Git workspace is refreshed,
- the stored ZIP must still physically exist,
- if it was deleted or moved, the Dashboard does not show it as valid and the
  event is written to the log.

This keeps Project Information useful after restart without weakening the
physical Export ZIP verification.

Identity: Build 297 / DEV001 FIX180.
