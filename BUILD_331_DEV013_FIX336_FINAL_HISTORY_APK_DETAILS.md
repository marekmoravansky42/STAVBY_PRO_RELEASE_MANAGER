# Build 331 / DEV013 / FIX336

FIX335 passed. DEV013 continues improving practical readability of older FINAL receipts.

FIX336:
- shows the persisted APK filename directly in each FINAL history record,
- shows persisted APK size in B / KB / MB,
- shows SHA-256 when the receipt contains it, truncated visually to avoid layout overflow,
- legacy receipts without these fields remain valid and display safe fallbacks,
- storage format and persisted receipt data are unchanged,
- newest-first ordering, timestamp, verification state and URL actions remain unchanged.

Identity: 8.0.0+331 / RC1 DEV013 FIX336.
