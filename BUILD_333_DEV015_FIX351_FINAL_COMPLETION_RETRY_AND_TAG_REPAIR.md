# Build 333 / DEV015 / FIX351 – FINAL Completion retry + tag repair

Reálny FINAL test STAVBY PRO 3.8.108 Build 482 odhalil, že Build Completion Center pre FINAL navrhoval všeobecný tag `v3.8.108`, ktorý už existoval. Commit prebehol, následný tag zlyhal a opakovaný pokus by sa snažil vykonať už hotové kroky znova.

FIX351:
- FINAL tag generuje jednoznačne ako `v<version>-final-b<build>` (pre testovaný release `v3.8.108-final-b482`), zhodne s FINAL Publish Center,
- opakované dokončenie bezpečne preskočí commit, ak už workspace nemá zmeny,
- existujúci tag na aktuálnom HEAD sa považuje za už hotový krok; tag na inom commite zostáva bezpečne blokovaný,
- návrh Release Notes už neprenáša anglické historické technické položky do používateľských Noviniek/Opráv; pri čisto anglickej histórii vytvorí slovenský súhrn.

Produkčný FINAL release STAVBY PRO sa týmto nemení; opravuje sa workflow Release Managera.
