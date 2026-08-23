# DEV001 FIX141 – Active project color + build identity

Dashboard:
- `Posledné udalosti` remains removed.
- Active project is now shown in a connected-status style similar to the Agent,
  but with a different color: blue/cyan instead of green.
- The active project row has blue background/border, folder icon and an
  `AKTÍVNY` badge so the selected project is immediately visible.

Release Manager identity:
- Release Manager build increased from 257 to 258.
- Canonical app version source updated to `DEV001 FIX141`.
- pubspec updated to `8.0.0+258`.
- This makes screenshots, diagnostics and the top-right version badge identify
  the exact test build instead of continuing to show stale FIX126/Build 257.
