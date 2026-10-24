# FIX366 – Existing FINAL tag resume

Reálny FINAL test ukázal, že po čiastočne dokončenom pokuse môže správny FINAL tag
už existovať na skoršom commite aktuálnej vetvy. Predchádzajúca logika vytvorila pri retry
ďalší commit a následne zablokovala existujúci tag, pretože nebol priamo na novom HEAD.

FIX366:
- pri retry nevytvára ďalší commit, ak požadovaný FINAL tag už existuje,
- existujúci tag akceptuje bez prepisu, ak označený commit je predok aktuálneho HEAD,
- tag mimo aktuálnej histórie vetvy zostáva bezpečne blokovaný,
- existujúci FINAL tag sa nikdy force-neprepisuje.

Produkčná logika ostatných FINAL krokov sa nemení.
