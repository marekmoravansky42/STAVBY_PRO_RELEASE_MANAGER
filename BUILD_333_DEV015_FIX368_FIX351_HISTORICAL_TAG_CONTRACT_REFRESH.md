# FIX368 – FIX351 historical tag contract refresh

FIX367 prešiel nové FIX366/FIX367 testy. Jediný zostávajúci fail bol historický FIX351 test,
ktorý ešte vyžadoval pôvodné pravidlo: existujúci FINAL tag musí ukazovať priamo na HEAD.

Po FIX366 je bezpečný kontrakt širší: tag môže zostať na skoršom commite, ak je tento commit
predkom aktuálneho HEAD. Tag sa nikdy force-neprepisuje a tag mimo aktuálnej histórie zostáva blokovaný.

FIX368 aktualizuje iba zastaraný historický test; produkčná recovery logika FIX366 sa nemení.
