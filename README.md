## 5.0.11 LTS Build 146

- Build History & Dashboard pre Windows workspace.
- Automatické uloženie úspešného kompletného Windows buildu.
- Trvalý lokálny súbor `build_history.json`.
- Prehľad posledného buildu a posledných ôsmich záznamov.
- Obnovenie a bezpečné vymazanie histórie.

# STAVBY PRO Release Manager 4.0.3 LTS Build 109

Stabilná LTS vetva Release Managera pre Windows a Android STAVBY PRO.

Verzia: 4.0.3+108

## Novinky

- Android APK Workflow má nový krok **Rozbaliť ZIP projektu** a po úspešnom rozbalení automaticky načíta projekt STAVBY PRO.
- Počas kompletného APK buildu sa každý úspešný krok postupne zafarbí nazeleno a označí fajkou.
- Pridaný **Export Android Release**.
- Android Release má vlastný uložený exportný priečinok, úplne nezávislý od Windows Export Release a GitHub nastavení.
- Export Android Release uloží APK pod štandardizovaným názvom a podľa dostupnosti pridá Release Notes a version.json.


## 5.0.9 LTS Build 144
Windows Workspace etapa 1: kontrola prostredia, kompletný build pipeline a stavový prehľad. Základom je stabilný Build 142 FIX 001.


## Build 146 – Android Workspace foundation
- centrálna synchronizácia verzie Release Managera
- Android preflight panel
- kontrola Flutter SDK, Git, pubspec.yaml, lib, android a APK výstupu


## 5.0.12 LTS Build 147
Android pipeline: Release APK + AAB, analýza veľkosti a SHA-256.
