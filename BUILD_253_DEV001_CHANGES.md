# STAVBY PRO Release Manager 7.0.2 LTS – Build 253 DEV001

## Execution Dashboard – etapa 1

- nový samostatný runtime model `PipelineStepExecution`,
- stav `waiting` pred spustením krokov,
- časy začiatku/ukončenia a živé trvanie,
- pripravené polia pre návratový kód, log a plugin ID,
- Execution Dashboard s progress barom a počítadlom krokov,
- zvýraznenie aktuálneho kroku,
- samostatné karty krokov so stavom a trvaním,
- súhrn úspešných, preskočených a chybných krokov,
- verzia zvýšená na 7.0.2+253 po úspešnom teste Build 252 FIX007.

## Overenie

Flutter SDK nie je v pracovnom prostredí dostupný. Je potrebné vykonať `flutter analyze`, `flutter test` a Windows build v Release Manageri.
