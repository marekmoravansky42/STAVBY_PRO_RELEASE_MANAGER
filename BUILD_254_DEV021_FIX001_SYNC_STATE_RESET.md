# Release Manager 7.1.0 LTS Build 254 DEV021 FIX001

## Workspace Sync State Reset

- po synchronizácii nového vývojového ZIP-u sa vymaže `.dart_tool`, plugin metadata a `build/`,
- One Click Build sa vždy resetuje na prvý krok `flutter clean`,
- staré EXE a exportné cesty sa zneplatnia,
- nie je možné omylom spustiť alebo exportovať zostavu z predchádzajúceho buildu,
- chyba `dart pub cache repair` zostáva iba pomocná diagnostika; rozhodujúci je výsledok nového čistého buildu.

## Test

1. Synchronizovať ZIP B270.
2. Overiť, že tlačidlo ponúka celý build od začiatku, nie pokračovanie od Analyze.
3. Spustiť celý build.
4. Pri chybe Analyze sa nesmie ponúknuť staré EXE ani vytvoriť úspešný export.
