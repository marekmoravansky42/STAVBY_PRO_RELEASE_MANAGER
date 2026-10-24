# FIX347 – negative/meta contract repair

FIX346 reduced failures from 16 to 2. Both remaining failures are historical
meta-test contracts, not production behavior.

FIX347:
- updates FIX329 to expect the generalized DEV regex in FIX327,
- updates FIX331 to expect that same generalized regex in FIX329,
- narrows FIX346's scan to positive stale current-stage matchers only,
- keeps Build 332 / DEV014 and the FINAL workflow unchanged.
