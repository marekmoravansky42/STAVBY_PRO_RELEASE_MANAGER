# RC1 Build 257 FIX006 – Backup Storage Manager

- Adds Backup Manager UI to workspace controls and Settings.
- Tracks Workspace_Backup_*.zip count and total storage size.
- Automatic retention after each successful Workspace Sync backup:
  - maximum target: 10 backups
  - maximum target size: 5 GB
  - newest 3 backups are always protected
- Manual “Vyčistiť staré” action keeps at least the newest 3 backups.
- Logs deleted files and released storage.
- Existing Workspace Sync lock-safe behavior from FIX005 is preserved.
