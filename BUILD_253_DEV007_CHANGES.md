# STAVBY PRO Release Manager 7.0.2 LTS – Build 253 DEV007

## Stabilization & Production Readiness

- Ukladanie Execution History používa dočasný súbor a atómovú výmenu, aby sa znížilo riziko poškodenia JSON pri prerušení zápisu.
- Poškodený alebo čiastočne neplatný záznam histórie už nezablokuje načítanie projektu.
- Jednotlivé neplatné položky histórie sa preskočia, pričom ostatné záznamy zostanú dostupné.
- Zlyhanie uloženia histórie už nezmení úspešnú pipeline na neúspešnú; používateľ dostane varovanie v živom termináli.
- Načítanie histórie je izolované od hlavného Execution Engine a pri chybe bezpečne vráti prázdny zoznam.
- História zostáva zoradená od najnovšieho behu a je obmedzená na 100 unikátnych záznamov.
- Doplnené automatické testy poškodeného JSON, radenia a limitu histórie.

Build zostáva 253, pretože ide o stabilizačnú DEV iteráciu.
