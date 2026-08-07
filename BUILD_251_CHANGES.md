# BUILD 251 CHANGES

## Funkčný cieľ
Používateľ môže otvoriť univerzálny Release Pipeline Designer, zapínať kroky, meniť ich poradie a uložiť šablóny.

## Technický cieľ
UI využíva existujúci dátový engine `lib/core/release_pipeline/` bez väzby na STAVBY PRO.

## Pridané
- nová navigácia **Pipeline** (`Ctrl+9`)
- zoznam univerzálnych pipeline šablón
- zapnutie/vypnutie krokov
- zmena poradia krokov
- ukladanie do existujúceho `PipelineStorage`
- obnova predvolených šablón
- automatizovaný test persistence

## Známe obmedzenia
- pipeline sa v tejto etape ešte nespúšťa
- zatiaľ bez importu/exportu jednotlivých JSON súborov
- bez drag & drop a podmienených vetiev

## Testovací plán
1. `flutter analyze`
2. `flutter test`
3. Windows build
4. Otvoriť **Pipeline**
5. Zmeniť poradie a stav kroku
6. Uložiť a reštartovať aplikáciu

## Kritériá úspechu
- 0 chýb analyzéra
- všetky testy prejdú
- Windows build je úspešný
- uložené poradie sa po reštarte zachová
