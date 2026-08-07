# Build 255 DEV003 — Git Preflight & Auto Fix

- Pred pushom kontroluje všetky Gitom sledované súbory voči limitu GitHubu 100 MB.
- Automaticky rozpozná generované build artefakty (`build/`, `.dart_tool/`, `*.pdb`, `*.ilk`, `*.obj`).
- Bezpečne ich odstráni iba z Git indexu, ponechá ich lokálne a doplní pravidlá do `.gitignore`.
- Aktualizuje posledný commit cez `git commit --amend --no-edit` a až potom vykoná push.
- Neznáme veľké súbory automaticky nemaže; zobrazí zrozumiteľnú výzvu na Git LFS alebo ručné rozhodnutie.
- Výsledkové okno obsahuje samostatný krok `Git preflight`.
