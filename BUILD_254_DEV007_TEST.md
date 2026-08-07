# Test Build 254 DEV007

1. Spusti Local Agent.
2. Vyber Flutter projekt, ktorý má iba analyzer `info`/`warning` nálezy.
3. Spusti `flutter analyze`.
4. Over, že karta je žltá a označená `UPOZORNENIA`, nie `CHYBA`.
5. Over počty Chyby/Upozornenia/Informácie.
6. Otestuj projekt so skutočnou analyzer chybou; výsledok musí zostať červený `CHYBA`.
