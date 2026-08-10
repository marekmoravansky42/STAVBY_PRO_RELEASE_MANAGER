# FIX064A – Snapshot Navigation Fix

Cause:
Snapshot Center was added as navigation page 12, but the shared navigation
guard still allowed only pages 0..11. Clicking Snapshot Center therefore did
nothing.

Fix:
- navigation now accepts page 12;
- Snapshot list refreshes automatically when Snapshot Center is opened;
- shortcut guard is kept consistent at 0..12;
- FIX064 Workspace Recovery remains included.
