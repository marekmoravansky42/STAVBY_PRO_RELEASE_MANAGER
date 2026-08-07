# Build 254 DEV003 – Remote Command Execution v1

- Release Agent prijíma úlohu `flutter analyze` cez HTTP API.
- Úloha sa vykonáva v explicitne zadanej ceste cieľového Flutter projektu.
- Agent poskytuje stav úlohy, živý log, trvanie a návratový kód.
- Release Manager pravidelne načítava priebeh a zobrazuje ho v karte Remote Command Execution.
- Agent blokuje súbežné spustenie druhej úlohy.
- Zachované sú Local Agent Mode, heartbeat, ping a manuálne LAN pripojenie.
