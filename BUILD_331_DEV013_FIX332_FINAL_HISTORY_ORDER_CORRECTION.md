# Build 331 / DEV013 / FIX332

FIX331 passed and closes the historical/meta-test repair chain.

Source inspection then found a real ordering defect in the FIX327 feature:
`_readFinalPublicationHistory()` already returns persisted receipts in reverse
order (newest first), while `_showFinalPublicationHistory()` reversed that list
again. The double reversal meant the UI could still display oldest first.

FIX332:
- removes the second reversal from the history dialog,
- preserves persisted JSON order and storage format,
- keeps the receipt count and existing history actions,
- refreshes FIX327/FIX328 source contracts,
- makes FIX331 identity assertion future-FIX compatible,
- adds a regression proving history is reversed exactly once.

Identity: 8.0.0+331 / RC1 DEV013 FIX332.
