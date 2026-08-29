# DEV001 FIX181 – Last Export corrupt-state guard

Follow-up to confirmed FIX180.

The persisted `Posledný export ZIP` state is now cleared before loading the
workspace-specific `last_export.json`. This prevents an old Dashboard export
path from another project from surviving when the new workspace metadata is
missing, malformed, unreadable, or otherwise fails to load.

The valid FIX180 persistence behavior remains unchanged.

Identity: Build 298 / DEV001 FIX181.
