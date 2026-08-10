# FIX061B – ProjectInfo Property Fix

Fixes the remaining Flutter analyze error from FIX061A.

`ProjectInfo` exposes `projectName`, not `name`, so the Portable Backup
diagnostic fallback now uses `_project?.projectName`.

All FIX061/FIX061A Portable Backup behavior remains unchanged.
