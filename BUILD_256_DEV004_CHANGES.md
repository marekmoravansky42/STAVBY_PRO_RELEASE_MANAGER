# STAVBY PRO Release Manager 8.0.0 — Build 256 DEV004

## Local Build Assistant + Workspace Manager

- Development Center priamo v obrazovke projektu.
- One Click Build používa existujúci overený build reťazec.
- Samostatné akcie Analyze, Test, Windows Release, Android APK a Android AAB.
- Workspace Manager vytvorí `.release_manager` pracovnú štruktúru: Builds, Exports, Profiles, Backups, Logs, Temp, Cache, Artifacts.
- Workspace Health kontroluje Flutter projekt, Git a spravované pracovné priečinky.
- Export Project Profiles do prenosného `.rmworkspace` súboru.
- Import `.rmworkspace` obnoví profily a aktívny projekt; existujúce cesty sú bezpečne overené pred otvorením.
- Zachovaná spätná kompatibilita s DEV003 Project Profiles a Recent Projects.

## Test

1. Otvor Project Profile.
2. Klikni PRIPRAVIŤ WORKSPACE.
3. Over WORKSPACE HEALTH.
4. Vyskúšaj Export `.rmworkspace` a následný Import.
5. Spusti Analyze/Test alebo ONE CLICK BUILD.
