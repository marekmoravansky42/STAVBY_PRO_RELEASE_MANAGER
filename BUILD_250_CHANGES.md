# STAVBY PRO Release Manager 6.5.3 LTS – Build 250

## Čo bolo pridané
- Karta **Nainštalované** v Plugin Center.
- Automatické načítanie pluginov z priečinka `plugins/`.
- Zobrazenie názvu, ID, verzie, API verzie, stavu a umiestnenia pluginu.
- Povolenie alebo zakázanie pluginu úpravou hodnoty `enabled` v `plugin.json`.
- Kopírovanie cesty a otvorenie priečinka pluginu.
- Atomický zápis manifestu cez dočasný súbor.

## Dôležité obmedzenie
Flutter desktop nedokáže bezpečne načítať a spustiť ľubovoľný Dart zdrojový kód z disku za behu. Build 250 preto spravuje nainštalované pluginové balíky a ich stav, ale nespúšťa cudzí Dart kód dynamicky. Funkčné rozšírenia musia byť skompilované spolu s aplikáciou a registrované cez existujúce Plugin SDK.

## Testovací plán
1. `flutter analyze`
2. Windows build
3. Otvoriť Pluginy → Nainštalované
4. Overiť zobrazenie nainštalovaného pluginu
5. Zakázať a znovu povoliť plugin
6. Overiť zmenu `enabled` v jeho `plugin.json`
7. Overiť kopírovanie cesty a otvorenie priečinka

## Kritériá úspechu
- 0 errors a 0 nových warnings.
- Nainštalované pluginy sa zobrazia.
- Prepínač stavu bezpečne aktualizuje manifest.
