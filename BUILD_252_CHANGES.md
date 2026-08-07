# Build 252 – Release Pipeline Executor Stage 1

## Čo bolo pridané
- Reálne spustenie vybranej pipeline z obrazovky Pipeline.
- Univerzálny register akcií oddelený od modelu pipeline.
- Podpora Flutter clean, pub get, analyze, test, Windows build, APK, AAB a Git status.
- Živý prenos výstupu príkazov do terminálového logu Release Managera.
- Stav každého kroku: čaká, beží, hotovo, chyba alebo preskočené.
- Súhrnný výsledok a trvanie pipeline.

## Známe obmedzenia
- Prvá etapa nepodporuje prerušenie už spusteného procesu.
- Diagnostický export je zatiaľ informačný krok.
- ZIP export a publikovanie budú registrované ako samostatné akcie v ďalších etapách.

## Testovací plán
1. flutter analyze
2. flutter test
3. Windows release build
4. Vybrať zdrojový projekt Release Managera
5. Otvoriť Pipeline a spustiť predvolenú šablónu
6. Overiť stavy krokov a živý terminál

## Kritériá úspechu
- Analyze bez issues.
- Všetky testy prejdú.
- Windows build je úspešný.
- Pipeline vykoná zapnuté kroky v uloženom poradí a zastaví sa pri chybe.
