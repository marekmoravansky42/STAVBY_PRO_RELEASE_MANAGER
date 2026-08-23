# DEV001 FIX132 – Correct One Click Release Export Order

FIX131 diagnostic proved that the failure was the premature ZIP export inside
One Click Build. At that moment Windows existed but Android APK had not yet
been built by One Click Release.

Correct order:
1. Analyze / Test / Windows Release
2. Android Release APK
3. Combined Windows + Android ZIP
4. Integrity / Publish Gate

Standalone One Click Build keeps automatic export.
One Click Release suppresses only the premature intermediate export.
FIX127–FIX131 remain included.
