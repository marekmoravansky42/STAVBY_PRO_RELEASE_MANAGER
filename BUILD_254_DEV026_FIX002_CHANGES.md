# Release Manager 7.1.0 LTS – Build 254 DEV026 FIX002

## Release Wizard – automatické načítanie rozbaleného projektu

- po výbere a rozbalení ZIP-u sa rozbalený koreň automaticky nastaví ako projekt pre krok **Build Release Managera**,
- automaticky sa načíta verzia a build z `pubspec.yaml`,
- predchádzajúci build/export stav sa bezpečne vynuluje,
- rozbalený projekt sa overí ako Flutter Windows projekt (`pubspec.yaml` + `windows/`),
- ručné tlačidlo **VYBRAŤ PROJEKT** zostáva dostupné a môže automaticky zvolený adresár kedykoľvek zmeniť,
- číslo buildu zostáva 254, pretože ide o FIX DEV026.

## Test

1. Otvor Release Wizard.
2. Klikni **VYBRAŤ A ROZBALIŤ ZIP**.
3. Po rozbalení skontroluj, že v kroku **Build Release Managera** je automaticky zobrazený názov rozbaleného priečinka.
4. Bez ručného výberu spusti kompletný Windows build.
5. Over, že tlačidlo **VYBRAŤ PROJEKT** stále umožní zvoliť iný adresár.
