# Build 316 DEV001 FIX261 – Windows Identity Transition

Release Manager now applies the same profile `androidLabel` to:
- Android manifest label,
- Windows native window title (`windows/runner/main.cpp`),
- Windows FileDescription and ProductName (`Runner.rc`).

The Windows files are included in the transition configuration backup, so
FINAL → DEV restore returns them safely to DEV as well.

This preserves one release profile as the DEV/FINAL source of truth.
