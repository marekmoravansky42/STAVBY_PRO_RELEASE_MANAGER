# DEV001 FIX143 – Last Build APK status

Dashboard / Posledný build:
- Added `APK Build` between `Windows Build` and `Export ZIP`.
- If a real APK exists at the last known APK path, status is `OK`.
- While Android/APK build is running, status is `PREBIEHA`.
- If Android/APK build fails, status is `CHYBA`.
- If the build did not produce/have an APK, status is `—` instead of a false `OK`.
- Existing Analyze/Test/Windows/Export statuses are unchanged.

Release Manager identity:
- Build 260
- DEV001 FIX143
