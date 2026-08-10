# FIX054A – Build Status Compatibility

Fix build for FIX054.

The new Dashboard build lifecycle used a Dart switch expression that is not
accepted by the project's current analyzer/language configuration. It has
been replaced by equivalent classic if/else logic.

Behavior remains unchanged:
PREBIEHA -> OK only after the exact build phase completes, ČAKÁ before it,
and CHYBA on failure.
