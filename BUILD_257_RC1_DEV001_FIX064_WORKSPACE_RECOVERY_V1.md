# FIX064 – Workspace Recovery v1

Built from confirmed FIX063A.

Adds restore from Snapshot Center.

Safety flow:
- user selects a snapshot and confirms restore;
- snapshot is unpacked to a temporary directory;
- Project Identity Guard verifies it belongs to the active project;
- current workspace is automatically backed up to
  `Backups/Recovery_PreRestore_*.zip`;
- snapshot files are restored in SAFE MODE: files present in the snapshot are
  added/overwritten, unrelated workspace files are not deleted;
- `.git` is preserved;
- derived Flutter state and One Click Build resume state are reset;
- project and Git status are reloaded after recovery.

Each snapshot row now has an `OBNOVIŤ` button.
