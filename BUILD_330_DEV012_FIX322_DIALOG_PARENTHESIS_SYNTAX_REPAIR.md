# Build 330 / DEV012 / FIX322 — Dialog Parenthesis Syntax Repair

- Opravuje syntaktickú regresiu zavedenú vo FIX321 v dvoch dialógoch v `lib/main.dart`.
- `_showReleaseHistoryDialog`: odstránené nadbytočné uzatvorenie `AlertDialog` pred `actions`.
- `_showFinalPublicationHistory`: doplnené chýbajúce uzatvorenie `SizedBox` pred `actions`.
- Funkčnosť FIX321 (70 % maxHeight a rolovateľná história FINAL publikovaní) zostáva zachovaná.
- Centrálny stage identity: `RC1 DEV012 FIX322`; pubspec zostáva `8.0.0+330`.
