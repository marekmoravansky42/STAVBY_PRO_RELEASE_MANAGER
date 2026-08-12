# FIX072 – Distribution Center v1

Built from confirmed-build FIX071.

Adds a new normal-mode sidebar page: Distribution Center.

It collects the current release outputs in one place:
- complete Release / FINAL release directory;
- Windows output;
- Android APK/AAB output when supported;
- Update directory;
- Reports directory;
- current Git repository/branch/change status.

Each available output has an OPEN action. The Git section can launch the
existing tested Git Build Publisher directly, or open Git Center.

FINAL release directories are recognized and marked `LTS / FINAL`.

v1 deliberately reuses existing build/release state and does not move or
duplicate release artifacts.
