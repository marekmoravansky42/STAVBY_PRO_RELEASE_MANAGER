# Build 254 DEV006 – Remote Windows Release Build

- Remote Agent protocol zvýšený na verziu 4.
- Pridaná capability `flutter_build_windows`.
- Nový endpoint `POST /tasks/build/windows`.
- Remote Agent vykoná `flutter build windows --release` v explicitne vybranom Flutter projekte.
- Release Manager zobrazuje živý log, stav, trvanie a návratový kód.
- Výsledok sa ukladá do existujúcej histórie agentových úloh.
- Staršie agenty bez protokolu 4 sa neprevezmú.
- Predvolený port pre DEV006 je 47834.
