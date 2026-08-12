# FIX076 – Release Integrity v1

Built from confirmed FIX075B.

Distribution Center adds `OVERIŤ INTEGRITU`.

For the currently detected release it:
- recursively reads the real release files;
- calculates SHA-256 for every payload file;
- creates `Reports/SHA256SUMS.txt`;
- immediately verifies all generated checksums;
- reports verified file count and total payload size;
- logs success/failure into dashboard operation status.

This provides a portable integrity manifest that can later be used to verify
that copied release files were not damaged or changed.
