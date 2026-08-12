# FIX075A – Release Platform Detection Fix

Fixes the incorrect Android=YES status reported for the Windows-only Release
Manager.

Previous behavior:
Release History treated the mere existence of `Windows` or `Android` folders
as proof that a platform had been built.

New behavior:
- Windows = YES only if a real `.exe` exists in the release Windows tree.
- Android = YES only if a real `.apk` or `.aab` exists in the Android tree.
- Reports = YES only if a real report file exists.
- empty/generated platform directories no longer count as built platforms.
- Release Compare inherits the corrected flags automatically.
- Distribution Center logs artifact-based platform detection as well.
