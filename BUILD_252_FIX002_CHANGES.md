# STAVBY PRO Release Manager 7.0.1 LTS – Build 252 FIX002

## Project Workspace & Preflight Validation

- pridaný explicitný výber cieľového Flutter projektu v Release Pipeline Designer,
- pipeline už nepoužíva implicitne zdrojový projekt Release Managera,
- validácia `pubspec.yaml` a Flutter SDK konfigurácie,
- automatická detekcia platforiem Windows, Android, Web, Linux, macOS a iOS,
- platformové požiadavky sú deklaratívnou súčasťou `PipelineStep`,
- nepodporované platformové kroky sa označia ako `SKIPPED` a pipeline pokračuje,
- pred spustením sa vykoná preflight kontrola projektu, platforiem a Flutter SDK,
- zachovaná kompatibilita starších uložených pipeline bez `requiredPlatforms`,
- pridané testy univerzálnej detekcie workspace a odmietnutia neplatného projektu.

Číslo verzie a buildu ostáva 7.0.1+252 podľa pravidiel FIX buildu.
