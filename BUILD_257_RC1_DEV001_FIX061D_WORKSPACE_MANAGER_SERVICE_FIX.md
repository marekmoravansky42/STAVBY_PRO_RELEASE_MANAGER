# FIX061D – Workspace Manager Service Fix

Fixes the Flutter analyze error introduced in FIX061C.

Cause:
Portable Backup called `_workspaceManagerService.exportBundle(...)`, but this
state class has no `_workspaceManagerService` field.

Fix:
Use the already imported stateless service directly:
`const WorkspaceManagerService().exportBundle(...)`

Portable New PC Export behavior remains unchanged.
