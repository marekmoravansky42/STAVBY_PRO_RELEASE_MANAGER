# FIX054C – Build Status Failed Token Fix

The FIX054B diagnostic identified the remaining parser failure at the
`failed.isNotEmpty && (...)` expression. The local `failed` identifier has
been replaced with `failedStepText` throughout the lifecycle helper.

No lifecycle behavior is changed:
ČAKÁ -> PREBIEHA -> OK, or CHYBA on failure.
