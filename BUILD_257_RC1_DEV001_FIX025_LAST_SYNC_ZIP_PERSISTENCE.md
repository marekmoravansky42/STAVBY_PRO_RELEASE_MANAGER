# FIX025 – Last Sync ZIP Persistence

Fixes Dashboard field `Posledný synchronizovaný ZIP`.

- successful Workspace Sync stores the exact ZIP filename in
  `.release_manager/last_sync.json`;
- the filename is loaded again when the workspace is refreshed/opened;
- restarting Release Manager no longer loses the value;
- the Dashboard row keeps the full exact ZIP filename and has a tooltip when
  the row is too narrow;
- FIX024 Git publish live progress and all previous fixes are preserved.
