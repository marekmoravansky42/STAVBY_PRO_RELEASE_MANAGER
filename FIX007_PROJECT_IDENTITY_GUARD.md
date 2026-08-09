# RC1 Build 257 FIX007 – Project Identity Guard
- Creates `.release_manager/project_identity_guard.json` for each selected workspace.
- Locks workspace identity to Flutter package name and, when available, Git origin remote.
- Synchronize ZIP validates the extracted ZIP project identity BEFORE backup, deletion or copy.
- A ZIP belonging to another Flutter project is blocked without modifying workspace files.
- One Click Build validates the workspace against its saved identity before build execution.
- FIX006 Backup Storage Manager remains included.
