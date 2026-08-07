# STAVBY PRO Release Manager 7.1.0 LTS – Build 254 DEV010 FIX002

## Update Detection Fix

- Opravená chybná kontrola aktualizácií, ktorá porovnávala aktuálnu aplikáciu s natvrdo uloženým Build 131.
- Kontrola teraz používa centrálnu hodnotu `ReleaseManagerVersion.build` (Build 254).
- GitHub release s rovnakou verziou a rovnakým buildom sa už neponúka ako novšia aktualizácia.
- Dialóg „Dostupná nová verzia“ sa zobrazí iba pri vyššej semantickej verzii alebo vyššom čísle buildu.
- Verzia aplikácie označená ako DEV010 FIX002.
