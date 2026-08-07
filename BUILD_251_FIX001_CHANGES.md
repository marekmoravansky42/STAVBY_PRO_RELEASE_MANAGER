# Build 251 FIX001

## Opravené
- Odstránené nesprávne volanie `_pipelineDesignerController.dispose()` z `_PreflightDialogState`, kde controller nie je dostupný.
- Uvoľnenie `ReleasePipelineDesignerController` bolo presunuté do `dispose()` hlavného `_ReleaseManagerPageState`, ktorý controller vlastní.

## Verzia
- Verzia zostáva `7.0.0+251`.
- Ide o opravu rovnakého buildu bez zvýšenia čísla buildu.

## Testovací plán
1. `flutter analyze`
2. `flutter test`
3. Windows build
4. Otvorenie sekcie Pipeline
5. Zmena poradia krokov, uloženie a opätovné načítanie
