# FIX348 – FIX347 test syntax literal repair

FAST DEV BUILD stopped in flutter analyze before tests because FIX347's own
regression test used an invalid nested quoted string at line 16.

FIX348 rewrites only that test assertion using a safe string literal and
future-proofs FIX347's identity assertion. Production code is unchanged.

Identity: 8.0.0+332 / RC1 DEV014 FIX348.
