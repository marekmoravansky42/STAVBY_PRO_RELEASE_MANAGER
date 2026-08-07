# Build 248 – Plugin Rollback Engine

## Čo bolo pridané
- PluginRollbackService pre vytváranie a obnovu záloh.
- Automatická záloha existujúceho pluginu pred aktualizáciou.
- Automatické obnovenie pôvodnej verzie pri zlyhaní aktualizácie.
- Záznam rollback operácií v transakčnom protokole.
- Test vytvorenia a obnovenia poslednej zálohy.

## Čo bolo opravené
- Opätovná inštalácia existujúceho pluginu sa spracuje ako bezpečná aktualizácia.

## Známe obmedzenia
- Ručný výber konkrétnej historickej zálohy ešte nie je v UI.

## Testovací plán
1. flutter analyze
2. Windows build
3. Inštalácia nového pluginu
4. Opätovná inštalácia novšej verzie rovnakého pluginu
5. Overenie vytvorenia zálohy v plugin_backups

## Kritériá úspechu
- 0 errors a 0 warnings z flutter analyze.
- Aktualizácia vytvorí zálohu a pri chybe obnoví pôvodný stav.
