# STAVBY PRO Release Manager 5.0.1 LTS – Build 136

## Kritická oprava: RELEASE_MANAGER Export Release adresár

- opravená chyba Windows `0x80070002` pri otvorení výberu priečinka,
- uložený počiatočný priečinok sa pred otvorením overí,
- pri chybe sa výber automaticky zopakuje bez `initialDirectory`,
- všetky chyby výberu sú zachytené a už neprepadnú do globálnej neobslúženej výnimky,
- doplnená diagnostika uloženého priečinka, jeho existencie a výsledku výberu,
- po výbere sa overí existencia adresára a nastavenie sa okamžite uloží,
- upravené označenie dialógu na RELEASE_MANAGER Export Release.

## Zdroj diagnostiky

`release_manager_crash.log` z Build 135 ukázal pád vo `FilePickerWindows._getDirectoryPathIsolate` s chybou `0x80070002`.
