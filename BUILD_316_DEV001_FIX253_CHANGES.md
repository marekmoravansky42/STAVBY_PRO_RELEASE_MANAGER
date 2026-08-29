# Build 316 DEV001 FIX253

- DEV → FINAL transition engine je prvýkrát napojený na reálny workflow.
- Poradie je povinné:
  1. zobraziť preflight,
  2. používateľ explicitne potvrdí,
  3. vytvorí sa config backup,
  4. až potom sa spustí transition engine,
  5. engine vykoná post-write verifikáciu.
- Ak používateľ zvolí Zrušiť, projekt zostane bez zmien.
- Zmena sa týka iba konfigurácie, nie používateľských dát.
