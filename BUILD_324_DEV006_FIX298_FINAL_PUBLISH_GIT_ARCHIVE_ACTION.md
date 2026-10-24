# Build 324 / RC1 DEV006 / FIX298 — FINAL Publish Git Archive Action

- FINAL Publish Center dostal priamu akciu **ULOŽIŤ FINAL DO GITU**.
- Ak workspace obsahuje zmeny, používa existujúci GitService.publishBuild (commit → tag → push vetvy → push tagu).
- Ak je workspace už čistý, vytvorí FINAL tag na aktuálnom HEAD a pushne vetvu aj tag.
- Existujúci FINAL tag sa nikdy automaticky neprepisuje.
- Po operácii sa spustí `_verifyFinalSourceArchive()` a Publish Center sa po úspechu znovu otvorí s aktuálnym checklistom.
- FIX295 verifikácia zostáva zdrojom pravdy pre Git Publish Gate.
