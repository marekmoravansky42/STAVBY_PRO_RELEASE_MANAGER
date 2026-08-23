# DEV001 FIX127 – One Click Release SemVer Parser

Problem:
- Release Recipe RC changes a project version from e.g. `3.8.91+465`
  to `3.8.91-rc.1+465`.
- `PubspecService` accepted only plain `x.y.z+build`, so One Click Release
  failed immediately after applying the RC recipe with:
  `FormatException: V pubspec.yaml chýba verzia vo formáte version: 1.2.3+4.`

Fix:
- PubspecService now accepts standard prerelease suffixes:
  - `3.8.91+465`
  - `3.8.91-rc.1+465`
  - `3.8.91-dev.1+465`
- Version update validation accepts the same prerelease format.
- The two Release Manager project/wizard version readers use the same parser.
- Added regression tests for stable, RC and DEV version forms.
- Release Manager remains 8.0.0 RC1 Build 257; this is DEV001 FIX127.
