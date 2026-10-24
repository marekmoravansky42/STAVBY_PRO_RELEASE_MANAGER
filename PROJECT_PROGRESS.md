# Stav projektu

Aktualizované: 2026-09-13 · Release Manager 8.0.0 RC1, Build 333, DEV015 FIX441.

## Skontrolované a uzavreté

- [x] **1. Project Analyzer** — funkcia už bola implementovaná; overená v zdrojoch.
- [x] **2. Build Completion: VYPLNIŤ VŠETKO** — FIX428 dopĺňa commit, popis, Novinky aj Opravy; manuálne potvrdené.
- [x] **3. Dvojité chybové dialógy** — FIX381; automatická a manuálna kontrola integrity zobrazia iba jedno chybové okno; regresný test prešiel.
- [x] **4. Bezpečné opätovné otvorenie FINAL procesu** — existujúce FINAL tagy a GitHub Release sa bezpečne znovu použijú; konflikty a prepis APK sú blokované alebo vyžadujú potvrdenie; regresné testy prešli.
- [x] **5. Audit Git zmien** — index je prázdny; pracovný strom obsahuje vedomé zdrojové zmeny aj lokálne cache, reporty a diagnostiky. Pri budúcom commite nezahrnúť generované dáta.
- [x] **6. Obnovenie Release Integrity dashboardu** — FIX429 okamžite vyčistí zastaraný release stav po nenájdení odstráneného výstupu; regresný test prešiel.
- [x] **7. Spätná väzba dlhých samostatných Flutter operácií** — FIX431 zobrazí priebeh a zablokuje súbežné akcie; regresný test prešiel.

## Budúce väčšie témy

- [ ] Auto Update
- [x] **15. Plugin SDK** — verejné rozhranie pluginov, descriptor a kompatibilita hosta, registry a lifecycle, manifest s API verziou, bezpečná inštalácia s kontrolou SHA-256 a rollbackom, Marketplace a generátor testovacieho pluginu sú implementované. 22 izolovaných testov a cielená statická kontrola prešli.
- [ ] Visual Pipeline Designer
- [x] **10. CI Runner** — FIX439 pridáva lokálne profily Rýchla kontrola, Plná kontrola, Windows a Android v aktuálnom workspace; každý profil sa spúšťa v samostatnom čitateľnom okne s tlačidlom Kopírovať chybu. Analyze bez skutočných chýb dokončí kontrolu s upozornením; priebeh už nie je duplicitne na hlavnej stránke, log sa otvára samostatne a okno CI využije takmer celú dostupnú obrazovku; manuálne potvrdené. GitHub Actions ostáva voliteľné budúce rozšírenie.
- [x] **11. Smart Rollback** — Snapshot Center obnovuje workspace až po vytvorení Recovery Backup-u a zachová Git metadáta; Git Center bezpečne obnovuje commit a pluginy majú rollback zo zálohy. Existujúce regresné testy prešli.
- [x] **12. Production Validator** — lokálny preflight overí workspace, platformy a Flutter SDK; Release Integrity overí SHA-256 manifest a vytvorí report; Publish Gate kontroluje stav, platnosť, manifest aj Project Profile a blokuje FINAL publikovanie pri chybe. Regresné testy a cielená statická kontrola prešli.
- [x] **13. Online overenie publikovania** — FIX440 ponechá FINAL Publish Center otvorené počas kontroly a po výsledku obnoví zobrazené online overenie aj uložený doklad; manuálne potvrdené.
- [x] **14. Čas online overenia v histórii** — FIX441 zobrazí pri každom doklade posledný čas online overenia v lokálnom čitateľnom formáte; manuálne potvrdené.
- [ ] Jednotné okno dlhých operácií — postupne zjednotiť samostatné Analyze/Test/Windows/Android buildy, importy a exporty: priebeh, čitateľné kroky, výsledok a kopírovanie chyby.
- [x] **8. Otvorenie CMD a PowerShellu** — FIX432 otvorí samostatné natívne okno vo vybranom workspace bez automatického vykonania príkazu; manuálne potvrdené.
- [x] **9. Visual Pipeline Designer** — šablóny, editácia krokov, validácia, priebeh, zrušenie a história spustení sú implementované; 6 izolovaných regresných testov prešlo.
- [ ] Zabudovaný terminál s písaním a spúšťaním príkazov priamo v aplikácii
