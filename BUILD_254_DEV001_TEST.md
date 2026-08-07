# Test Build 254 DEV001

1. Na počítači agenta spusti `tools/release_agent/START_RELEASE_AGENT.bat`.
2. Pri prvom spustení povoľ prístup vo Windows Firewall pre súkromnú sieť.
3. V Release Manageri otvor kartu **Agenti**.
4. Pre test na rovnakom PC použi `127.0.0.1`, port `47831`.
5. Pre druhý PC zadaj jeho lokálnu IP adresu, napríklad `192.168.1.25`.
6. Klikni **PRIPOJIŤ / OBNOVIŤ**.
7. Over názov PC, OS, Flutter a platformy.
8. Klikni **PING AGENT** a over výsledok `OK` a latenciu.
9. Zastav agenta a po ďalšom obnovení over hlásenie nedostupnosti.

DEV001 ešte nespúšťa vzdialený Flutter príkaz.
