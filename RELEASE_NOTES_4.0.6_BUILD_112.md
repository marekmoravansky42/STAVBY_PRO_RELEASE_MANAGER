# STAVBY PRO Release Manager 4.0.6 LTS Build 112

- Opravené rozpoznanie DEV/BETA/RC pri Android APK exporte.
- Typ vydania sa zisťuje z celej cesty projektu, nie iba z posledného segmentu.
- DEV projekt sa exportuje napr. ako STAVBY_PRO_3.5.28_DEV_BUILD_102.apk.
- Pri DEV/BETA/RC exporte sa odstráni starý súbor rovnakej verzie bez označenia vetvy.
- Release Notes pri exporte používajú rovnaké rozlíšenie vetvy.
