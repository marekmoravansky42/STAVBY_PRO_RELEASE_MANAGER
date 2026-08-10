# FIX038 – Non-Destructive Workspace Sync

Emergency safety fix built directly from confirmed FIX035.

Workspace Sync no longer deletes the existing project tree before copying a ZIP.
The selected ZIP only adds or overwrites files that it contains.

This prevents workspace data loss when:
- Local Agent or another process locks a file,
- synchronization is interrupted,
- a ZIP is incomplete,
- deletion succeeds before a later copy step fails.

Automatic backup and Project Identity Guard remain enabled.
.git, .release_manager, .dart_tool and build exclusions remain unchanged.
