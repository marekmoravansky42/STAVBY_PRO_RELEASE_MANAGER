# STAVBY PRO Release Manager 7.1.0 LTS – Build 254 DEV013 FIX001

## Git Build Publisher – parser fix

- Opravená syntakticky neplatná regulárna expresia v `lib/main.dart`.
- Parser identifikátora vývojovej fázy teraz bezpečne rozpozná hodnoty v jednoduchých aj dvojitých úvodzovkách.
- Zachovaný workflow Git Build Publisher v1: status → add → commit → tag → push vetvy → push tagu.
- Číslo buildu zostáva 254; ide o FIX aktuálneho DEV013.
