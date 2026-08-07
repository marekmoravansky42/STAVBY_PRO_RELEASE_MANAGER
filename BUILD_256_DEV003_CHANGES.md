# Build 256 DEV003 – Project Profiles

- Pridaný Project Profiles panel do sekcie Projekt a workspace.
- Profily sa ukladajú perzistentne do `%APPDATA%\STAVBY_PRO_RELEASE_MANAGER\Profiles`.
- Nový profil vyberie Flutter projekt cez natívny folder picker a automaticky zistí Windows/Android platformy.
- Jedným kliknutím možno prepínať medzi uloženými projektmi; profil obnoví projekt aj Git workspace.
- Aktívny profil sa automaticky obnoví pri ďalšom štarte Release Managera.
- Pridané akcie Premenovať, Duplikovať a Odstrániť profil bez zásahu do súborov projektu.
- Model ProjectProfile bol rozšírený o Git branch a release type pri zachovaní kompatibility so staršími JSON profilmi.
- Zoznam Naposledy použité projekty zostáva zachovaný ako spätná kompatibilita.

## Test DEV003
1. Otvor Projekt a workspace.
2. Klikni NOVÝ PROFIL a vyber Flutter projekt.
3. Vytvor aspoň dva profily a prepni medzi nimi.
4. Over, že sa zmení aktívny projekt/workspace.
5. Zavri a znovu spusti Release Manager; posledný aktívny profil sa má automaticky načítať.
