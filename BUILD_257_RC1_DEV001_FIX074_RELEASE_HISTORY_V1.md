# FIX074 – Release History v1

Built from confirmed FIX073.

Adds Release History under Overview.

The page scans the same real release roots used by Distribution Center and
shows up to 30 newest release directories with:
- release/final directory name;
- modification date/time;
- Windows / Android / Reports presence;
- LTS / FINAL badge;
- direct OPEN action.

The history is reconstructed from real folders on disk, so it survives
application restarts and workspace synchronization. No release data is moved
or modified.
