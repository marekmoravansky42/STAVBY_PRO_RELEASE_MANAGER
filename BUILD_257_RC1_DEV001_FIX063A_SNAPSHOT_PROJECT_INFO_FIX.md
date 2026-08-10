# FIX063A – Snapshot ProjectInfo Fix

Fixes the Flutter analyze error from FIX063.
`ProjectInfo` exposes `build`, not `buildNumber`, so Snapshot metadata now uses
`_project?.build`.

No Snapshot Center behavior is otherwise changed.
