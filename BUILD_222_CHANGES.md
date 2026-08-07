# STAVBY PRO Release Manager 6.2.5 LTS – Build 222

## Diagnostics & Logging Extraction – Fáza 1

- pridaný samostatný `DiagnosticsController`,
- živý terminálový log presunutý zo stavu hlavnej obrazovky do diagnostického modulu,
- centralizované časové značky logov,
- pridaný bezpečný limit 5000 záznamov,
- pridané jednotné operácie `tail`, `clear` a `exportText`,
- diagnostický balík a report používajú centralizovaný zdroj logov,
- pridaný model `DiagnosticsReport` pre ďalšie fázy extrakcie,
- existujúce diagnostické dialógy a workflow zostali funkčne nezmenené.

Verzia: `6.2.5+222`
