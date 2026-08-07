# Build 246 – Plugin Installation Validation

## Čo bolo pridané
- Bezpečná predinštalačná validácia marketplace pluginov.
- Kontrola povinných údajov, Plugin API, minimálnej verzie Release Managera, URL a SHA-256.
- Informatívne upozornenie na chýbajúci digitálny podpis a odloženú kontrolu oprávnení balíka.
- Tlačidlo **Overiť inštaláciu** v Marketplace.
- Výsledkový dialóg a textový inštalačný protokol.

## Čo bolo opravené
- Synchronizovaná verzia na `6.4.9+246`.

## Známe obmedzenia
- Build 246 ešte nesťahuje ani nekopíruje pluginové balíky.
- Oprávnenia sa overia až po stiahnutí a rozbalení `plugin.json`.
- Digitálny podpis zatiaľ nie je povinný.

## Testovací plán
1. `flutter analyze`
2. Windows release build
3. Otvoriť položku **Pluginy**
4. Pri demo plugine zvoliť **Overiť inštaláciu**
5. Overiť výsledný dialóg a protokol

## Kritériá úspechu
- 0 errors a 0 warnings z `flutter analyze`
- úspešný Windows build
- všetkých päť demo pluginov prejde blokujúcimi kontrolami
