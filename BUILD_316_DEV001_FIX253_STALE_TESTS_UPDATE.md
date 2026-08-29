# FIX253 – stale contract tests update

No production FINAL workflow code changed.

Updated only:
- test/fix253_confirm_apply_final_transition_test.dart
- test/fix253_transition_engine_scope_fix_test.dart

Reason:
The tests still asserted the pre-deferred FIX253 source shape, while the
current workflow intentionally applies FINAL only after DEV analyze + test
and immediately before platform builds.
