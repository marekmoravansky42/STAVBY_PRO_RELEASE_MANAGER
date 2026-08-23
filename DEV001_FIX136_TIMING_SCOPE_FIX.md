# DEV001 FIX136 – Timing helper scope fix

FIX135 introduced DEV fast release correctly, but its timing helper was inserted
into the wrong function because a generic `var success = false; try {` anchor
matched an earlier method.

Flutter analyze therefore reported:
- `logPhaseDuration` unused near line 9767
- `logPhaseDuration` undefined in `_runOneClickReleaseComplete`
- `releaseStartedAt` undefined in `_runOneClickReleaseComplete`

FIX136:
- removes the misplaced helper,
- defines `releaseStartedAt`, `phaseStartedAt` and `logPhaseDuration` locally
  inside `_runOneClickReleaseComplete`,
- keeps the FIX135 speed optimization unchanged:
  DEV skips clean + pub get; RC/FINAL remain FULL.
