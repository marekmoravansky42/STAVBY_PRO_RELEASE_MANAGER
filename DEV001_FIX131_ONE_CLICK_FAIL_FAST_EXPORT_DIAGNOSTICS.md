# DEV001 FIX131 – One Click Fail-Fast + Export Diagnostics

Observed:
- ONE CLICK RELEASE could display a failure but then continue with later steps.
- The combined export used PowerShell `Copy-Item -LiteralPath ...\*`; `-LiteralPath`
  does not expand the wildcard reliably, so Windows staging could fail.
- The failure dialog did not provide enough diagnostic context.

Fix:
- ONE CLICK RELEASE now checks the embedded FULL BUILD result immediately.
  Any analyze/test/Windows failure throws and stops the release workflow.
- Exact failed step and up to 12 captured output lines are included in the error.
- Combined Windows staging now uses native Dart recursive file copy.
- Staging is validated to contain at least one EXE.
- If the project supports Android, combined export is forbidden unless a real
  release APK exists; an incomplete Windows-only package is not silently accepted.
- ONE CLICK RELEASE failure writes a crash/diagnostic report and shows a
  selectable detailed error dialog stating that the workflow was stopped.
- FIX127–FIX130 remain included.
- Release Manager remains 8.0.0 RC1 Build 257; this is DEV001 FIX131.
