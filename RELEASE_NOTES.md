# STAVBY PRO Release Manager 4.0.3 LTS Build 109

## Android APK Workflow

- Pridané rozbaľovanie ZIP projektu priamo ako prvý krok Android workflow.
- Po rozbalení sa projekt automaticky načíta.
- Flutter clean, pub get, analyze, test a Release APK build sa po úspechu postupne zazelenajú a dostanú fajku.
- Pridaný Export Android Release.
- Android export používa vlastný samostatne uložený priečinok; Windows export zostáva nezávislý.

## Stabilita

- Existujúci Windows Release Wizard a GitHub workflow zostali oddelené a bez zmeny logiky.
