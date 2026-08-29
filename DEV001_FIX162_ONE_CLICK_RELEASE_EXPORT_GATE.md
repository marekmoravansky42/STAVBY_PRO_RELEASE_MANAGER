# FIX162 – One Click Release Export Gate

Root cause found: the One Click Release ZIP creation was inside the
`androidProject` branch. Release Manager itself has no Android platform, so the
branch was skipped. Integrity and Publish Gate then continued against an older
release directory while the current build displayed Export ZIP as waiting.

FIX162:
- Windows-only projects now create the Release ZIP after skipping APK,
- both Android and Windows-only ZIPs must exist and have non-zero size,
- a mandatory Export Gate runs before SHA-256 / Release Integrity,
- One Click Release cannot report success without a current physical ZIP,
- completion dialog accurately reports missing Android as skipped,
- completion dialog can open the verified ZIP directly in Explorer.

Identity: Build 279 / DEV001 FIX162.
