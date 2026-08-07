# Release Manager 8.0.0 RC1 Build 257 FIX002

## Git Remote Fallback

- Lokálny Git repozitár bez `origin` už nezastaví Build Completion Center.
- Git preflight pri chýbajúcom `origin` vykoná lokálne kontroly a preskočí iba kontroly vzdialenej histórie.
- Git push sa pri chýbajúcom `origin` bezpečne preskočí a výsledok zostane úspešný s jasnou informačnou správou.
- Commit a tag zostanú uložené lokálne.
- Rovnaké správanie bolo doplnené aj do Git Build Publisher služby.
- Existujúci Project Snapshot Engine z FIX001 zostáva zachovaný.

## Version

- Version: 8.0.0
- Build: 257
- Channel: RC1 FIX002
- Build číslo sa nezvyšuje, pretože ide o opravný build RC1.
