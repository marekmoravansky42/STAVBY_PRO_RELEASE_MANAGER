# FIX067 – Snapshot Management

Built from confirmed FIX066.

Snapshot Center management additions:
- show snapshot detail (size, date, project, version, build, original workspace);
- mark one snapshot as `BEZPEČNÝ BOD`;
- safe-point marker is persisted in the Snapshots directory;
- safe point is highlighted in the list;
- safely delete old snapshots with confirmation;
- deleting a safe snapshot also clears its safe-point marker;
- snapshot metadata sidecar is deleted together with the ZIP.

FIX064 Workspace Recovery and FIX066 Git repository binding remain included.
