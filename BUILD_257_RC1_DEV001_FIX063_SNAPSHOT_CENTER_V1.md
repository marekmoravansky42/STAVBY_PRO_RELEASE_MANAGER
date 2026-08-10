# FIX063 – Snapshot Center v1

Built from confirmed FIX062.

Adds a dedicated Snapshot Center to the Project section.

v1 features:
- create a manual snapshot of the active workspace;
- snapshots are stored beside the workspace in `Snapshots`;
- excludes `.git`, `.dart_tool`, `build`, `.release_manager`;
- writes a small JSON metadata sidecar;
- shows the latest 10 snapshots with date and size;
- refresh list / open snapshot folder.

This first step only creates and manages restore points.
Workspace Recovery / Restore from Snapshot follows after this build is tested.
