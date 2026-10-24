# Build 331 / DEV013 / FIX330

FAST DEV BUILD for FIX329 reached 359 passing tests and one failure.
The only failure was FIX328's historical test pinning exact stage FIX328
while canonical identity correctly advanced to FIX329.

FIX330:
- refreshes FIX328 historical identity assertion to accept later FIXes in DEV013,
- proactively refreshes FIX329's own identity assertion the same way,
- keeps FIX327 newest-first FINAL publication history unchanged,
- adds a regression guard against exact FIX327/FIX328/FIX329 identity pins.

Identity: 8.0.0+331 / RC1 DEV013 FIX330.
