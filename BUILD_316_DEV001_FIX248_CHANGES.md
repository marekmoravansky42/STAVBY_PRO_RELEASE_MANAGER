# Build 316 DEV001 FIX248

- Release Manager načíta projektový `release/stavby_pro_release_profile.json`.
- FULL BUILD pred spustením pipeline overí profil a zaloguje aktívny DEV/FINAL channel.
- Integrácia je zámerne read-only: FIX248 ešte neprepisuje package ID, databázu ani dátové cesty.
- Neplatný profil zastaví FULL BUILD pred zásahom do projektu.
- Projekty bez profilu pokračujú kompatibilným režimom.
