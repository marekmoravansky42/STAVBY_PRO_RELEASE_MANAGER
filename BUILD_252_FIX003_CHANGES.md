# STAVBY PRO Release Manager 7.0.1 LTS – Build 252 FIX003

## Opravy po diagnostike FIX002

- Doplnený import rozšírenia `ProjectPlatformLabel` do preflight validátora.
- Výber cieľového adresára migrovaný na statické API `FilePicker.getDirectoryPath()` kompatibilné s `file_picker 11.0.3`.
- `ReleasePipelineExecutionController` bol kompletne zjednotený na modeli `ProjectWorkspace`.
- Všetky vstavané pipeline akcie teraz dostávajú explicitný workspace.
- Command runner používa výhradne `workspace.rootPath` ako pracovný adresár cieľového projektu.
- Odstránené neplatné a zmiešané volania parametrov `workingDirectory`/`workspace`.
- Build číslo ostáva 252, pretože FIX002 neprešiel `flutter analyze`.

## Overenie

Balík je určený na opätovné spustenie:

1. `flutter analyze`
2. `flutter test`
3. Windows release build

Až po úspechu všetkých krokov môže nasledovať Build 253.
