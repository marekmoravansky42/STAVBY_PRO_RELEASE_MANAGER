# Build 331 / DEV013 / FIX337

FIX336 FAST DEV BUILD stopped at flutter analyze due only to the new FIX336 test.

The test contained:
- an invalid Matcher == bool comparison,
- a non-raw `$apkSha256` source snippet that Dart tried to interpolate inside the test.

FIX337:
- removes the invalid matcher/bool assertion,
- checks the SHA-256 production source with a raw Dart string,
- keeps FIX336 production APK history details unchanged,
- makes FIX336 identity assertion future-FIX compatible,
- adds a focused regression contract.

Identity: 8.0.0+331 / RC1 DEV013 FIX337.
