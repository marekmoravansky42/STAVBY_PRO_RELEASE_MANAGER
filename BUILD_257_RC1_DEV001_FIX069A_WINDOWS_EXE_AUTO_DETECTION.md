# FIX069A – Windows EXE Auto Detection

Fixes RC/LTS Release Wizard validation after a successful Windows build.

- removes hard-coded `stavby_pro_dev.exe`;
- scans the actual Flutter `build/windows/**/runner/Release/` output;
- uses the real generated application EXE name;
- EXE launch/status messages also display the detected filename;
- DEV/TEST recipes and all FIX068/FIX067 functionality remain included.
