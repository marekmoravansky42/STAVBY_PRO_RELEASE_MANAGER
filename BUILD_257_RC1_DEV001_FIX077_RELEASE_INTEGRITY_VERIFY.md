# FIX077 – Release Integrity Verify

Built from confirmed FIX076.

Distribution Center now separates integrity into two explicit operations:

- `VYTVORIŤ SHA-256 MANIFEST` creates/refreshes `Reports/SHA256SUMS.txt` from the current release payload.
- `SKONTROLOVAŤ INTEGRITU` reads the existing manifest and verifies the release without modifying it.

Verification detects:
- missing files;
- modified files with a different SHA-256;
- invalid or unsafe manifest paths;
- malformed manifest entries.

The result is written to the live log and Dashboard operation status. A failed verification shows the affected files and does not rewrite or repair the release.
