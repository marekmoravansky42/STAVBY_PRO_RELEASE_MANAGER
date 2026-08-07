# Release Manager 5.0.6 LTS – Build 141

## Bezpečná obnova buildu

- História commitov obsahuje nové tlačidlo **Obnoviť tento build**.
- Obnova je povolená iba pri čistom pracovnom adresári.
- Release Manager pred obnovou vytvorí bezpečnostnú vetvu `backup/pre-restore-*`.
- Vybraný commit otvorí v novej vetve `restore/<commit>-*`.
- Vetva `dev`, pôvodný commit ani Git história sa neprepisujú.
- Pri necommitnutých zmenách sa operácia bezpečne zablokuje.
