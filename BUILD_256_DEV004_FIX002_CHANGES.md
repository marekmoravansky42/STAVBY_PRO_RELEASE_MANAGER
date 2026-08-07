# STAVBY PRO Release Manager 8.0.0 — Build 256 DEV004 FIX002

## Opravy

- Opravené `undefined_identifier` pre `extra` v `_WorkflowStepCard`.
- Odstránený zvyšný nepoužívaný UI blok `extra`, keďže DEV004 ho už neposiela.
- Odstránený `unnecessary_non_null_assertion` pri spustení Release Pipeline (`workspace!` -> `workspace`).
- Build číslo zostáva 256 podľa FIX workflow.

## Cieľ testu

Quick Build musí prejsť cez `flutter analyze`, `flutter test` a Windows Release build bez blokujúcej chyby.
