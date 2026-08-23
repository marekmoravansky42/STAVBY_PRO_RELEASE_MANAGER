# DEV001 FIX133 – Update Fail-Fast Regression Test

Diagnostic:
- Application code in FIX132 intentionally changed the One Click Release call to:
  `_runOneClickBuild(fastMode: false, exportReleaseZip: false)`
- The older FIX131 contract test still searched for the obsolete exact call:
  `_runOneClickBuild(fastMode: false)`
- Therefore Flutter test returned -1 even though the release code change was intentional.

Fix:
- Updated the regression test to expect the FIX132 call with
  `exportReleaseZip: false`.
- Fail-fast ordering assertions remain unchanged:
  FULL BUILD -> failure check -> Android.
- No runtime release logic changed in FIX133.
