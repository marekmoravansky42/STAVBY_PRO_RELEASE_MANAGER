# DEV001 FIX166 – RC/FINAL reset to DEV + correct export filename stage

User test found two real issues:
1. after RC / FINAL, the One Click selector remained on RC/FINAL even though the
   pubspec restoration logic ran;
2. FINAL export ZIP was named with `RC1` because `_createOneClickReleaseZip()`
   used Release Manager's own identity.stage instead of the current project's
   release recipe/version.

FIX166:
- RC / FINAL now restore the project to DEV and also reset/persist the One Click
  mode itself to DEV;
- export version/build now come from the current pubspec project;
- export stage is derived from the current pubspec version:
  `-dev` → DEV, `-rc` → RC, no suffix → FINAL;
- therefore FINAL ZIP names explicitly contain `_FINAL_`.

Identity: Build 283 / DEV001 FIX166.
