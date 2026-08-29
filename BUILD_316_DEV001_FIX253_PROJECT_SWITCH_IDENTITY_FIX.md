# FIX253 – Project Switch Identity Fix

Problem:
Po otvorení STAVBY_PRO sa `_project` prepol, ale `_gitWorkspacePath` zostal
na Release_Manager. Karta Informácie o projekte preto miešala:
- projekt/cestu STAVBY_PRO,
- verziu/build Release Managera.

Oprava:
- `_gitWorkspacePath` sa pri otvorení projektu okamžite nastaví na `selected`,
- starý Git stav/história/identity snapshot sa vyčistia,
- zvolený projekt sa uloží aj ako Git workspace,
- `_refreshGitWorkspace()` načíta Git vetvu, commit a ProjectVersionProvider
  priamo zo zvoleného projektu,
- ZIP metadata ostávajú project-scoped.

FIX253 FINAL workflow sa nemení.
