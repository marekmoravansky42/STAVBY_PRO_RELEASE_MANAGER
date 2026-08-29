# FIX253 FINAL UI + DEV restore

- Tlačidlo FINAL v Release Recipe už nekončí iba výberom profilu.
- FINAL teraz spustí kontrolovaný FULL BUILD, ktorého prvým krokom je DEV → FINAL preflight.
- Používateľ musí preflight explicitne potvrdiť.
- Pred apply sa vytvorí config backup.
- Po builde alebo pri chybe sa workspace automaticky obnoví zo zálohy späť do DEV konfigurácie.
- Používateľské dáta sa nemenia.
