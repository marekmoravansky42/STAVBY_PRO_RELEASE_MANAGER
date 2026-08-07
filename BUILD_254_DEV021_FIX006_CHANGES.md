# STAVBY PRO Release Manager 7.1.0 LTS Build 254 DEV021 FIX006

## Workspace Project Reload Fix

- Po úspešnej synchronizácii vývojového ZIP-u sa objekt `_project` znovu načíta priamo z aktuálneho `pubspec.yaml` vo workspace.
- Dashboard už nezostane na identite projektu načítanej pred synchronizáciou.
- `PubspecService` a Project Version Provider sa po synchronizácii navzájom overia.
- One Click Build pred spustením znovu načíta projekt z workspace a zastaví sa pri nesúlade identity.
- Dialóg, Build Report a Export Release ZIP tak používajú aktuálnu identitu workspace.

## Test

1. Spusti FIX006.
2. Synchronizuj ZIP B273 (`3.6.99+273`).
3. Po dokončení synchronizácie musí Dashboard okamžite ukázať `3.6.99 DEV` a Build `273`.
4. Spusti celý build.
5. Záverečný dialóg a Export Release ZIP musia obsahovať Build `273`.
