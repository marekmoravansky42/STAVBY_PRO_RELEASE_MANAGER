# Test Build 254 DEV003 FIX003

1. Extract the ZIP and build/run Release Manager.
2. Open **Agenti**.
3. Confirm the default Local Agent port is **47832**.
4. Click **SPUSTIŤ LOCAL AGENT**.
5. Confirm the agent remains ONLINE.
6. Select a valid Flutter project containing `pubspec.yaml`.
7. Click **SPUSTIŤ FLUTTER ANALYZE**.
8. Confirm the task starts without `HttpException: Not found`, live output appears, and an exit code is shown.

An older agent may still be running on port 47831; FIX003 intentionally uses 47832 so it cannot be adopted accidentally.
