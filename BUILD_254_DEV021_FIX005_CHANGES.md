# STAVBY PRO Release Manager 7.1.0 LTS – Build 254 DEV021 FIX005

## Single Project Version Provider

- Aktuálny `pubspec.yaml` pracovného projektu je jediný zdroj verzie a buildu.
- Dashboard používa explicitne obnovený snapshot identity projektu.
- Workspace Sync po kopírovaní nastaví a znova overí identitu projektu.
- One Click Build načíta identitu cez rovnaký provider pred buildom aj po ňom.
- Build Report, Export Release ZIP, Git commit a tag používajú tú istú identitu.
- Pri nesúlade sa synchronizácia alebo build bezpečne zastaví.
