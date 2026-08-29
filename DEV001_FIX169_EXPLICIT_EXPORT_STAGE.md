# DEV001 FIX169 – Explicit export stage

User test found that FAST DEV BUILD produced a `_FINAL_` ZIP name. The reason
was that FIX166 inferred the export stage only from `pubspec.yaml`. The Release
Manager development source itself uses a stable `8.0.0+build` pubspec, so a
standalone FAST DEV BUILD was incorrectly interpreted as FINAL.

FIX169:
- `_createOneClickReleaseZip()` accepts an explicit release stage,
- FAST DEV BUILD / FULL BUILD and standalone Dashboard Export ZIP explicitly
  use `DEV`,
- ONE CLICK RELEASE explicitly passes the selected `DEV`, `RC` or `FINAL`,
- Build Completion Center passes its selected release type,
- pubspec inference remains only as a fallback.

Expected FAST DEV export:
`STAVBY_PRO_RELEASE_MANAGER_8.0.0_DEV_BUILD_286_WINDOWS_RELEASE.zip`

Identity: Build 286 / DEV001 FIX169.
