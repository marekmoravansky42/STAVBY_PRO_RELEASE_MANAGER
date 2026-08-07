# STAVBY PRO Release Manager 4.0.14 LTS Build 120

## STAVBY PRO – WINDOWS: spoľahlivý samostatný proces
Workflow bol zjednodušený presne na:
1. Rozbaliť ZIP
2. flutter analyze
3. flutter build windows
4. Spustiť stavby_pro_dev.exe
5. Export Windows Release

### Diagnostika EXE
- Release Manager už nepovažuje samotné Process.start za úspešné spustenie.
- Po spustení stavby_pro_dev.exe sleduje proces 5 sekúnd.
- Ak EXE skončí skôr, zobrazí čas behu a EXIT CODE a krok zostane neúspešný.
- Ak proces zostane bežať aspoň 5 sekúnd, krok sa označí ako úspešný.
- Export je povolený až po úspešnom teste spustenia EXE.

Android APK workflow zostáva samostatný a nezmenený.
