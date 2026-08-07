# Release Manager 8.0.0 RC1 Build 257 FIX001

## Git Branch Compatibility
- Removed hard-coded `develop` requirement from Build Publisher.
- Build Publisher now works on the repository's currently active branch.
- New Project Profiles detect the current Git branch automatically.
- Project Profile menu now allows editing the preferred Git branch.
- Missing branch in older profiles is treated as automatic detection.

## Project Snapshot Engine v1
- One Click Build creates a safety snapshot before a fresh build starts.
- Build/cache/Git folders are excluded from snapshots.
- Manual Create Snapshot and Restore Last Snapshot actions were added to Project Profiles page.
- Build Failure diagnostics can restore the last snapshot directly.
- Snapshots are stored outside the workspace under `.release_manager_snapshots`.

## Compatibility
- Version remains 8.0.0 and Build remains 257 because this is RC1 FIX001.
- Existing RC1 project profiles remain readable.
