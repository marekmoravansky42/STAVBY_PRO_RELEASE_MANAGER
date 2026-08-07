# STAVBY PRO Release Manager 6.2.4 LTS – Build 221

## Release Wizard State Extraction – Fáza 1

- Pridaný `ReleaseWizardController`.
- Stav behu, aktuálny krok, text stavu, výstupný report a release adresár boli vyčlenené z `main.dart`.
- Zoznam pipeline krokov je centralizovaný v module Release Wizard.
- Pridané bezpečné API pre prípravu, priebeh, dokončenie a reset sprievodcu.
- Existujúci Release Wizard workflow a používateľské rozhranie zostali funkčne nezmenené.
- Verzia synchronizovaná na `6.2.4+221`.
