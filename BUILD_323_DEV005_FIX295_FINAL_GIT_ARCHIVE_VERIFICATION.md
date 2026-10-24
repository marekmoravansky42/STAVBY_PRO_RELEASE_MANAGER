# Build 323 / RC1 DEV005 / FIX295 — FINAL Git archive verification

FINAL Publish Center no longer treats a clean Git workspace as proof that the FINAL source archive exists.
It verifies the expected `v<version>-final-b<build>` tag locally and on origin, verifies that the tag points to HEAD, and verifies that HEAD equals the configured upstream branch. The Publish Gate requires all of these checks.
