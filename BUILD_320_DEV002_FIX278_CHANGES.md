# BUILD 320 • RC1 DEV002 FIX278

- Opravené poradie lokálnych funkcií v AI Build Completion Center.
- `suggestedDescription()` je deklarované pred `suggestedDescriptionFromHistory()`, takže fallback už nie je referencovaný pred deklaráciou.
- Zachované načítanie histórie zmien z BUILD/DEV change súborov.
- Aktualizovaná kanonická identita na RC1 DEV002 FIX278.
- Uvoľnený historický FIX276 identity kontrakt, aby ďalšie FIXy neblokoval.
- Pridaný regresný test poradia deklarácií a aktuálneho badge.
