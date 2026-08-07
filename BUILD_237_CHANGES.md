# STAVBY PRO Release Manager 6.4.0 LTS – Build 237

## Plugin Package Manager Foundation

- validácia rozbalených pluginových balíkov cez `plugin.json`
- kontrola API kompatibility, oprávnení a entry pointu
- bezpečná inštalácia pluginov do oddeleného adresára
- aktualizácia so zálohou a automatickým rollbackom pri chybe
- odinštalovanie s voliteľnou zálohou
- odmietnutie symbolických odkazov v balíku
- jednotkové testy inštalácie, validácie, aktualizácie a odinštalovania

Poznámka: ZIP import bude nad touto bezpečnou adresárovou vrstvou doplnený v ďalšej etape; jadro Build 237 nepoužíva nespustený cudzí kód.
