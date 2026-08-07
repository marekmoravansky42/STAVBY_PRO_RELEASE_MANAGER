# BUILD 250 FIX001

## Opravené

- Opravený automatizovaný test `installed_plugin_service_test.dart`.
- Testovací manifest teraz používa platnú sémantickú Plugin API verziu `1.0.0`, ktorú vyžaduje `PluginManifestParser`.
- Produkčná funkcionalita Installed Plugin Center zostala nezmenená.

## Verzia

- Release Manager: `6.5.3 LTS`
- Build: `250`
- Pubspec: `6.5.3+250`

## Testovací plán

1. `flutter analyze`
2. `flutter test`
3. Windows release build
4. Pluginy → Nainštalované
5. Zmena stavu Povolený/Zakázaný
