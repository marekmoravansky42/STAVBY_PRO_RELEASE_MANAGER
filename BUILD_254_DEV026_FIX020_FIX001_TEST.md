# DEV026 FIX020 FIX001 – Pipeline Storage Async Fix

## Oprava
- `ReleasePipelineDesignerController.load()` čaká na uloženie vybratej pipeline.
- Cieľový priečinok stavu sa vytvorí rekurzívne pred zápisom.
- Test už nemôže odstrániť dočasný priečinok počas prebiehajúceho zápisu.

## Test
1. Spusti `flutter analyze`.
2. Spusti `flutter test`.
3. Over, že `release_pipeline_designer_test.dart` prejde bez `PathNotFoundException`.
4. Zostav Windows Release Manager.
