# Build 247 – Plugin Installation Engine

## Čo bolo pridané
- Reálna inštalácia pluginu z rozbaleného lokálneho adresára.
- Transakčný inštalačný protokol.
- Bezpečné kopírovanie cez existujúci PluginPackageManager.
- Validácia plugin.json, API verzie, oprávnení a entryPointu pred zápisom.
- Výber zdrojového priečinka priamo z Plugin Marketplace UI.

## Čo bolo opravené
- Verzia a build boli synchronizované na 6.5.0+247.

## Známe obmedzenia
- Build 247 neinštaluje plugin priamo z online ZIP URL.
- Zdrojový plugin musí byť vopred rozbalený a obsahovať plugin.json.
- Aktivácia bez reštartu bude riešená v ďalšom builde.

## Testovací plán
1. flutter analyze
2. Windows build
3. Otvoriť Pluginy
4. Vybrať rozbalený pluginový adresár
5. Overiť fyzické skopírovanie do plugins/<pluginId>
6. Overiť zobrazenie inštalačného protokolu

## Kritériá úspechu
- 0 errors a 0 nových warnings
- platný plugin sa nainštaluje
- neplatný plugin sa odmietne bez čiastočne skopírovaných súborov
