# FIX059 – Last Operation Running State

Built from confirmed FIX058.

When a new Dashboard operation starts, the previous green OK is cleared.
`Posledná operácia` now follows PREBIEHA -> OK / CHYBA instead of showing a
stale result from the previous operation.

Applied to One Click Build, Workspace Sync, quick Analyze/Test/Windows/Export,
and Obnoviť stav. Existing FIX055–FIX058 lifecycle behavior is preserved.
