# Build 254 DEV003 FIX004 – Project Picker & Validation

- odstránená nesprávna automatická cesta `Directory.current`
- pridané systémové tlačidlo **VYBRAŤ PROJEKT**
- validácia `pubspec.yaml` pred odoslaním úlohy agentovi
- automatické dohľadanie Flutter projektu najviac dve úrovne pod vybraným priečinkom
- tlačidlo `SPUSTIŤ FLUTTER ANALYZE` je aktívne iba pre platný projekt
- zachované API protokolu 2, heartbeat, ping a Local Agent na porte 47832
