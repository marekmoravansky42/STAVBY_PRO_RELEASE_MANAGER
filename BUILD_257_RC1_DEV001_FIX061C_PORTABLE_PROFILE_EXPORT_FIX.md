# FIX061C – Portable Profile Export Fix

Built from confirmed FIX061B.

The first Portable Backup was only ~1.5 KB because the exporter looked in the
wrong Project Profiles directory (`project_profiles`). The real persistent
directory is `Profiles`.

Changes:
- exports JSON files from the real `Profiles` directory;
- always creates `project_profiles.rmworkspace` from the profiles currently
  loaded in Release Manager;
- adds `export_manifest.json` with profile counts and backup metadata;
- keeps credentials excluded;
- existing portable settings export remains unchanged.

This prepares the package for FIX062 New PC Restore / Import.
