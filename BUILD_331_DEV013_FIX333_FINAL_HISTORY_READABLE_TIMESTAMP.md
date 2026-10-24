# Build 331 / DEV013 / FIX333

FIX332 passed. DEV013 continues with practical readability of older FINAL
publication receipts.

FIX333:
- formats stored ISO publication timestamps in the history UI as local
  `DD.MM.YYYY HH:MM`,
- preserves the persisted ISO timestamp and JSON storage format unchanged,
- falls back to the original stored text if an older timestamp cannot be parsed,
- keeps newest-first ordering, receipt count, URLs and actions unchanged,
- refreshes FIX332 identity contract so later DEV013 FIXes remain valid.

Identity: 8.0.0+331 / RC1 DEV013 FIX333.
