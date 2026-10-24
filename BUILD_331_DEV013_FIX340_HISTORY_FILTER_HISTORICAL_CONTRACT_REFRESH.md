# Build 331 / DEV013 / FIX340

FIX339 production/filter tests passed, but three historical source-contract tests failed
because they still expected the pre-filter displayHistory/title implementation.

FIX340 refreshes only those historical contracts:
- FIX327 newest-first contract now accepts filtered displayHistory,
- FIX328 dynamic title contract accepts visible/total counts,
- FIX332 single-reverse contract accepts the filtered display list,
- production FIX339 filter implementation is unchanged,
- FIX339 identity assertion is future-FIX compatible.

Identity: 8.0.0+331 / RC1 DEV013 FIX340.
