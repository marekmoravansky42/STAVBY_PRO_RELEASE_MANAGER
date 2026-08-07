# Build 254 DEV007 – Analyze Severity Classification

- `flutter analyze` už nie je automaticky označený ako CHYBA iba preto, že vráti exit code 1.
- Ak log obsahuje iba `info` alebo `warning` nálezy a žiadny `error`, výsledok sa zobrazí ako UPOZORNENIA.
- Pridané počítadlá chýb, upozornení a informačných nálezov.
- Červený stav zostáva iba pre skutočné chyby alebo výnimky.
- História agentových úloh ukladá normalizovaný stav aj pôvodný stav agenta.
