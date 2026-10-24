# Build 319 DEV001 FIX271 — Export ZIP history

- Každý úspešný Release ZIP export vytvorí nový samostatný súbor.
- Existujúci ZIP sa už nikdy automaticky neprepisuje ani nemaže.
- Ak posledný Workspace Sync ZIP obsahuje FIX číslo, export ho prenesie do názvu (napr. `_FIX267_`).
- Opakovaný export rovnakého FIXu dostane bezpečný číselný suffix `_2`, `_3`, ...
- Staré exporty zostávajú používateľovi ako rollback záloha a mažú sa iba ručne.
