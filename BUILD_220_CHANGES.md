# STAVBY PRO Release Manager 6.2.3 LTS – Build 220

## Git Workspace State Extraction – Fáza 1

- Pridaný `GitWorkspaceController`.
- Stav vybraného Git workspace bol presunutý z `main.dart`.
- Stav repozitára, načítania, commitu, tagu, diffu a bezpečného obnovenia je centralizovaný.
- História commitov je spravovaná controllerom.
- Existujúce Git príkazy, dialógy a používateľské rozhranie zostali funkčne nezmenené.
- Controller sa korektne uvoľňuje cez `dispose()`.
- Verzia projektu je synchronizovaná na `6.2.3+220`.
