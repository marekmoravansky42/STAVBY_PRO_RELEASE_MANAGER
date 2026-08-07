# BUILD 254 DEV026 FIX045 FIX001

## Automatic Build Identity Manager

- Opravená identita aplikácie na `DEV026 FIX045 FIX001`.
- `lib/app/app_version.dart` zostáva jediným zdrojom identity Release Managera.
- Pridaný nástroj `tools/update_release_identity.ps1`.
- Pridaný jednoduchý spúšťač `tools/UPDATE_RELEASE_IDENTITY.bat`.
- Nástroj aktualizuje verziu, kanál, build aj vývojovú fázu na jednom mieste.
- Dashboard, hlavička, diagnostika a reporty používajú `ReleaseManagerVersion`.
