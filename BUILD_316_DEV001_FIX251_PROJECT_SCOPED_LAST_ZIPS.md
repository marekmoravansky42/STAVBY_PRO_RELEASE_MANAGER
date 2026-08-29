# FIX251 Project-scoped last ZIP metadata

Pri prepnutí projektu sa teraz okamžite vyčistia údaje z predchádzajúceho projektu:
- Posledný synchronizovaný ZIP
- Posledný export ZIP

Následne sa obe hodnoty načítajú z metadata súborov aktuálne vybraného projektu.

Výsledok:
- STAVBY_PRO zobrazuje iba svoje ZIP metadata.
- Release_Manager zobrazuje iba svoje ZIP metadata.
- Ak aktuálny projekt metadata nemá, zobrazí sa prázdny stav namiesto hodnoty z predchádzajúceho projektu.
