# Build 331 / DEV013 / FIX342

FIX341 passed. Adds a direct SHA-256 copy action to each FINAL history receipt.
The action copies the full persisted APK hash, is disabled for legacy receipts
without a hash, and confirms successful clipboard copy. Existing history data,
ordering, filtering and receipt copy behavior remain unchanged.

Identity: 8.0.0+331 / RC1 DEV013 FIX342.
