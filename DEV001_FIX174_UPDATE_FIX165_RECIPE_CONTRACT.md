# DEV001 FIX174 – Update stale FIX165 recipe contract

FIX173 intentionally changed DEV suffix construction from string concatenation
to interpolation. Runtime behavior is identical, but the old FIX165 structural
test still searched for the literal source fragment `+ '-dev.1'`.

FIX174 updates that stale expectation to the interpolation form `}-dev.1'`.
No runtime code is changed.

Identity: Build 291 / DEV001 FIX174.
