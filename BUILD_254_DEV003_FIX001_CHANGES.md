# Build 254 DEV003 FIX001

- izolované spracovanie každej HTTP požiadavky Release Agenta,
- chyba alebo odpojenie jedného klienta už nesmie ukončiť celý agent proces,
- bezpečné zatváranie HTTP odpovedí,
- globálne zachytenie neočakávaných asynchrónnych chýb agenta,
- zachovanie posledných diagnostických riadkov stdout/stderr,
- zobrazenie konkrétnej diagnostiky pri neočakávanom ukončení,
- manuálne zastavenie agenta sa už nehlási ako neočakávaný pád,
- zachované Remote flutter analyze, heartbeat a ping.
