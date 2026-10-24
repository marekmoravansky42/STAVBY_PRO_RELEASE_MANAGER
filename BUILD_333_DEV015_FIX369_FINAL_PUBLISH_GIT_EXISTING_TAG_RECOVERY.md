# FIX369 – FINAL Publish Git existing-tag recovery

Reálny FINAL test ukázal rozdiel medzi Git workflowmi. Build Completion Center už po FIX366
vedel bezpečne zachovať existujúci FINAL tag, ale akcia ULOŽIŤ FINAL DO GITU v FINAL Publish
Centeri stále existujúci tag blokovala.

FIX369 zjednocuje správanie:
- existujúci lokálny FINAL tag sa akceptuje iba ak je na HEAD alebo v histórii aktuálneho HEAD,
- origin tag musí ukazovať na rovnaký zdrojový commit ako lokálny tag,
- chýbajúci push vetvy/tagu sa môže bezpečne doplniť,
- existujúci tag sa nikdy force-neprepisuje,
- konflikt mimo aktuálnej histórie zostáva blokovaný,
- neskoršie lokálne pracovné zmeny už samy osebe nezneplatnia už archivovaný FINAL zdroj.
