# STAVBY PRO Release Manager 4.0.14 LTS – Build 120

STAVBY PRO – WINDOWS má nový prehľadný krokový workflow:
1. Rozbaliť Windows ZIP
2. Flutter analyze
3. Príprava Windows buildu
   - flutter clean
   - odstránenie windows\flutter\ephemeral
   - flutter pub get
4. Flutter build windows --release
5. Spustiť stavby_pro_dev.exe
6. Export Windows Release

Každý dlhší Flutter krok používa samostatný priebeh/stav rovnako ako APK workflow.
Bezpečné čistenie ephemeral z Build 118 zostalo zachované.
