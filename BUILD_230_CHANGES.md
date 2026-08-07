# STAVBY PRO Release Manager 6.3.3 LTS – Build 230

## Release Pipeline Templates – Fáza 1

- Pridané deklaratívne modely `PipelineTemplate` a `PipelineStep`.
- Pridaný validátor pipeline a kontrola duplicitných krokov.
- Pridaný `PipelineExecutor` s registráciou akcií, stavmi krokov a bezpečným zastavením po chybe.
- Pridané JSON úložisko používateľských pipeline šablón.
- Pridané predvolené šablóny Full Release, Windows Release, Android Release, Diagnostics a Git Sync.
- Pridané automatizované testy serializácie, validácie a zastavenia pipeline po chybe.
- Existujúci Release Wizard zostáva funkčne nezmenený; nový modul tvorí kompatibilný základ pre jeho ďalšie napojenie.
