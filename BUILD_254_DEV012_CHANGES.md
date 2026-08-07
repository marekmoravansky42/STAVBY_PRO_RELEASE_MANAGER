# STAVBY PRO Release Manager 7.1.0 LTS – Build 254 DEV012
## Parallel Pipeline Engine v1

- Pipeline kroky majú explicitné závislosti.
- Pripravené nezávislé kroky sa môžu spustiť súčasne na rôznych agentoch.
- Jeden agent je počas jednej paralelnej vlny rezervovaný iba pre jeden krok.
- AUTO scheduler vyberá kompatibilného voľného agenta pre každý pripravený krok.
- Manuálne priradenie agentov zostáva zachované.
- Zlyhanie závislosti označí nadväzujúce kroky ako Preskočené.
- Detegujú sa nesplniteľné alebo cyklické závislosti.
- Execution Dashboard zobrazuje súčasne bežiace kroky, agentov a závislosti.
- Pri jednom Local Agentovi sa pipeline vykoná bezpečne sekvenčne.
