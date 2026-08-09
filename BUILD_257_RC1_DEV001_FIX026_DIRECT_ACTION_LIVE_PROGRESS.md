# FIX026 – Direct Dashboard Actions + Live Progress

Dashboard work buttons now run their real operation directly:
- Analyze
- Flutter Test
- Windows Build
- Export ZIP

All four use the existing unified activity/progress panel:
- operation title,
- percentage,
- progress bar,
- current live output/status.

This removes the previous behavior where Analyze/Test/Windows only navigated to
another page and Export ZIP launched a full FAST DEV BUILD.

FIX025 persistent last synchronized ZIP name, FIX024 Git progress and previous
guards are preserved.
