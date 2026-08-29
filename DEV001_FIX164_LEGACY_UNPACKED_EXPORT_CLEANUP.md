# DEV001 FIX164 – Legacy unpacked export cleanup

FIX163 stopped creating a new unpacked copy in the user-facing export folder,
but directories created by older builds (for example FIX162) naturally remained
on disk.

FIX164 performs a targeted cleanup after a successful ZIP export:
- only directories belonging to the current project are considered,
- they must be One Click release package names containing `_BUILD_`,
- they must end in `_WINDOWS_RELEASE` or `_WINDOWS_ANDROID_RELEASE`,
- most importantly, the matching `<directory>.zip` must physically exist,
- only then is the old unpacked duplicate removed.

The internal `.release_integrity_cache` is untouched and continues to support
Release Integrity / Publish Gate after restart.

Identity: Build 281 / DEV001 FIX164.
