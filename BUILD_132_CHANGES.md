# STAVBY PRO Release Manager 4.0.26 LTS – Build 132

## Oprava diagnostiky chýb

- Plné diagnostické okno sa otvorí po neúspešnom Flutter príkaze.
- Zobrazenie diagnostiky už nezávisí od úspešného uloženia reportu do projektu.
- Ak automatické uloženie zlyhá, report zostane viditeľný a dá sa uložiť cez **ULOŽIŤ AKO**.
- Pred otvorením diagnostiky sa zatvorí kompaktné spodné hlásenie.
- Dialóg používa hlavný navigátor, aby nezostal skrytý pod aktuálnou vrstvou UI.
- Zachované sú možnosti kopírovania pre ChatGPT, exportu diagnostického ZIP-u a otvorenia priečinka.
