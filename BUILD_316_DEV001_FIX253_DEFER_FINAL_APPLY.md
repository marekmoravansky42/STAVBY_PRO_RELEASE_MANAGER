# FIX253 – defer FINAL apply until after DEV tests

Problem:
- FINAL konfigurácia sa aplikovala ešte pred `flutter test`.
- STAVBY PRO testy sú DEV contract testy, preto správnu FINAL identitu vyhodnotili ako chybu.

Oprava:
1. FINAL preflight + explicitné potvrdenie.
2. Vytvorenie config backupu.
3. `flutter clean` + `pub get` + `analyze` + `test` stále v DEV konfigurácii.
4. Až pred Windows/Android buildom sa aplikuje DEV → FINAL.
5. Transition engine overí FINAL hodnoty.
6. Windows/Android artefakty sa zostavia ako FINAL.
7. V `finally` sa workspace obnoví zo zálohy späť do DEV.

Používateľské dáta sa nemenia.
