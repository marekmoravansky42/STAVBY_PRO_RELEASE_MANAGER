# Build 331 / DEV013 / FIX334

FIX333 FAST DEV BUILD stopped at flutter analyze.

Production timestamp formatter was not the cause. The new FIX333 source-contract
test embedded Dart source snippets containing `${...}` inside ordinary strings,
so the test file itself tried to evaluate `two`, `local`,
`_formatFinalPublicationTimestamp` and `item`.

FIX334:
- converts those two expected source snippets to raw Dart strings,
- keeps the FIX333 production timestamp formatter unchanged,
- makes FIX333 identity assertion future-FIX compatible,
- adds a focused regression test for the literal/interpolation repair.

Identity: 8.0.0+331 / RC1 DEV013 FIX334.
