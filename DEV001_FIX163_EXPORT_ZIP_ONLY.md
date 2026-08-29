# DEV001 FIX163 – Export folder contains ZIP only

Observed after FIX162:
- One Click Release correctly created the ZIP,
- but it also left the unpacked release directory beside the ZIP.

That unpacked copy is required internally for SHA-256 Release Integrity and
Publish Gate, including restoration after a Release Manager restart. It should
not be presented as a second user-facing export.

FIX163:
- the unpacked working copy is moved to
  `<workspace>/.release_integrity_cache/<release package>`,
- the user-facing export directory keeps only the resulting ZIP,
- Distribution Center now scans `.release_integrity_cache` so Integrity and
  Publish Gate still restore correctly after restart,
- the previous internal cache is cleared before registering the current release.

Identity: 8.0.0 RC1 • Build 280 • DEV001 FIX163.
