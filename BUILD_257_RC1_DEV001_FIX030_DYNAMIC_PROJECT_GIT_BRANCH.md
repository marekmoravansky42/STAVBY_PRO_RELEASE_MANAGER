# FIX030 – Dynamic Project Git Branch

- Removed the hard-coded `develop` requirement from **Uložiť build do Gitu**.
- Git publishing now uses the active branch of the currently selected workspace.
- Release Manager can therefore publish from `dev`, while another project can use `develop` or another branch.
- The Git Developer Center text now displays the branch that will actually be validated.
- Includes confirmed FIX029 and all previous fixes.

Next planned step: Project Profiles window for one-click switching between saved projects.
