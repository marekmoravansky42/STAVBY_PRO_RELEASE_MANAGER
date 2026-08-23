# DEV001 FIX130 – One Click Release Combined Windows + Android Export

Problem:
- FIX129 created Android APK, but the automatic Export Release ZIP was still
  produced inside `_runOneClickBuild` before the APK step and therefore
  contained only the Windows application.

Fix:
- Export Release ZIP now stages platform artifacts into:
  - `Windows/` – full Windows Release directory
  - `Android/` – generated release APK when available
- After the One Click Android APK build, the release ZIP is generated again
  as the authoritative combined Windows + Android package.
- Combined ZIP name ends with `_WINDOWS_ANDROID_RELEASE.zip`.
- If no APK exists, regular standalone Export ZIP safely creates
  `_WINDOWS_RELEASE.zip`.
- Temporary staging directory is always deleted.
- Dashboard export status/log explicitly reports Windows and Android presence.
- FIX127 SemVer, FIX128 DEV/RC/FINAL selector and FIX129 APK build remain included.
- Release Manager remains 8.0.0 RC1 Build 257; this is DEV001 FIX130.
