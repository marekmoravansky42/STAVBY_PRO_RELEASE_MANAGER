# Build 332 / DEV014 / FIX346

FIX345 removed stale Build 331 pins. FAST DEV BUILD then exposed the second half
of the same historical identity contract: 16 DEV013 tests still required DEV013
as the current stage.

FIX346 generalizes those historical stage checks while preserving their feature
assertions. Production FINAL workflow code is unchanged.

Updated historical stage contracts: 16
Identity: 8.0.0+332 / RC1 DEV014 FIX346.
