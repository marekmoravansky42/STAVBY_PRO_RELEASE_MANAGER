# Build 249 – Test Plugin Generator

## Čo bolo pridané

- Tlačidlo **Vytvoriť testovací plugin** pri každom plugine v demo Marketplace.
- Automatické vytvorenie kompletného testovacieho balíka:
  - `plugin.json`
  - `README.md`
  - `CHANGELOG.md`
  - `LICENSE`
  - `lib/plugin.dart`
  - `test/plugin_test.dart`
  - `assets/`
- Generovaný plugin používa rovnaké ID, názov, verziu a Plugin API ako vybraná položka Marketplace.
- Po vytvorení aplikácia zobrazí presnú cestu, ktorú treba vybrať cez **Inštalovať z priečinka**.

## Známe obmedzenia

- Generovaný plugin je testovací zdrojový balík; Release Manager nespúšťa cudzí Dart kód dynamicky.
- Ak cieľový priečinok s rovnakým ID už existuje, generovanie sa bezpečne zastaví.

## Testovací plán

1. Otvoriť sekciu **Pluginy**.
2. Pri ľubovoľnom demo plugine kliknúť na **Vytvoriť testovací plugin**.
3. Vybrať nadradený priečinok.
4. Overiť vytvorenú štruktúru.
5. Kliknúť na **Inštalovať z priečinka** a vybrať vytvorený plugin.
6. Overiť vytvorenie zálohy pri opakovanej inštalácii novšej verzie.
