# FIX062 – New PC Restore / Import

Built from confirmed FIX061D Portable Backup.

Adds `IMPORT / OBNOVIŤ NA NOVOM PC` next to Portable Export.

Restore flow:
- selects a Release Manager Portable Backup ZIP;
- validates the manifest/settings/workspace files;
- restores sanitized app settings;
- restores all Project Profiles;
- validates every old absolute project path;
- activates a profile only when its project directory actually exists;
- reports paths that need to be selected again on the new PC;
- never imports GitHub/DPAPI credentials.

This is the matching restore half of FIX061 Portable New PC Export.
