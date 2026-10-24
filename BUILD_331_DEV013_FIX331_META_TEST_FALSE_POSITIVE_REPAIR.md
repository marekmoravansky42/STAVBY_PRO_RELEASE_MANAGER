# Build 331 / DEV013 / FIX331

FIX330 FAST DEV BUILD reached 361 successful tests and one failure.

The failure was inside FIX330's new meta-regression guard. The guard searched
for the literal `contains(... RC1 DEV013 FIX327 ...)` anywhere in recent tests
and therefore incorrectly rejected FIX329's legitimate negative assertion:

`isNot(contains("stage = 'RC1 DEV013 FIX327';"))`

That assertion is evidence that the stale FIX327 pin is absent; it is not a
positive identity pin.

FIX331:
- repairs FIX330 meta-test to reject only positive exact historical identity pins,
- preserves FIX329's valid negative historical assertion,
- keeps Build 331 / DEV013 and all FINAL publication-history production code unchanged,
- adds a focused regression test for this false-positive case.

Identity: 8.0.0+331 / RC1 DEV013 FIX331.
