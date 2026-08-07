# Test Build 254 DEV019

1. Vyber pracovný projekt `C:\SP\STAVBY_PRO`.
2. Klikni **SPUSTIŤ CELÝ BUILD**.
3. Pri chybe musí Release Manager automaticky otvoriť diagnostické okno a uložiť report do `diagnostics/` pracovného projektu.
4. Po zatvorení diagnostiky musí hlavné tlačidlo ponúknuť pokračovanie od neúspešného kroku.
5. Po oprave zdroja klikni na pokračovanie; `flutter clean` a `flutter pub get` sa nemajú opakovať, ak chyba vznikla neskôr.
6. Tlačidlo **ZAČAŤ OD ZAČIATKU** musí vymazať stav pokračovania.
7. Po úspechu musí dialóg zobraziť súhrn všetkých piatich krokov.
