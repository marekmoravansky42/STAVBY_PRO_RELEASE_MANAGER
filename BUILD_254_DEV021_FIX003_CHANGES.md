# STAVBY PRO Release Manager 7.1.0 LTS – Build 254 DEV021 FIX003

## Dynamic Version Refresh

- po Workspace Sync sa povinne overí, že verzia v cieľovom workspace zodpovedá vybranému ZIP-u,
- One Click Build načíta identitu projektu priamo z `pubspec.yaml` pri štarte,
- po dokončení buildu sa identita načíta znova a porovná so štartovacou hodnotou,
- pri nesúlade sa nevytvorí report, exportný ZIP, Git commit ani tag so zlým číslom,
- dialóg, Build Report, Export Release ZIP a Git Publisher používajú aktuálnu identitu projektu.
