# STAVBY PRO Release Manager 7.0.2 LTS – Build 253 RC001

## Release Candidate

RC001 vychádza z úspešne otestovaného Build 253 DEV007.

### Režim vydania

- code freeze – bez nových funkcií,
- verzia projektu zostáva `7.0.2+253`,
- označenie aplikácie doplnené o `RC001`,
- zachované stabilizačné opravy Execution History z DEV007,
- zachovaný koreňový adresár balíka `B253/`.

### Povinné validačné kroky

1. `flutter clean`
2. `flutter pub get`
3. `flutter analyze`
4. `flutter test`
5. `flutter build windows --release`

### Manuálne scenáre

- výber a validácia Project Workspace,
- úspešná pipeline,
- pipeline s preskočenou platformou,
- pipeline s chybou,
- manuálne zastavenie pipeline,
- vyčistenie výsledku,
- uloženie a opätovné načítanie Execution History,
- načítanie a vykonanie pluginového pipeline kroku.

Pri chybe sa pripraví RC001 FIX build bez zvýšenia čísla buildu.
