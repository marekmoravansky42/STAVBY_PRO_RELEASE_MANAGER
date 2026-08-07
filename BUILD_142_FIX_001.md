# Release Manager 5.0.7 LTS Build 142 – FIX 001

## Oprava flutter analyze

- Opravené nekompatibilné volanie `FilePicker.platform.saveFile(...)`.
- Pre `file_picker 11.0.2` sa používa statické API `FilePicker.saveFile(...)`, rovnako ako v ostatných častiach projektu.
- Funkcia exportu Git Diff reportu do TXT zostáva zachovaná.

Diagnostická chyba: `undefined_getter` v `lib/main.dart:888`.
