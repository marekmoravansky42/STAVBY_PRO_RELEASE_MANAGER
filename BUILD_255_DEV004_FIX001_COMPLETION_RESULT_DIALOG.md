# Release Manager 8.0.0 DEV – Build 255 DEV004 FIX001

## Completion Result Dialog Fix

- Po kliknutí na Dokončiť build sa okamžite zobrazí blokujúce okno s priebehom.
- Aktuálny krok sa priebežne aktualizuje (Commit, Preflight, Push, ZIP, Report, História).
- Obnovenie Git workspace má časový limit 10 sekúnd a už nemôže zablokovať výsledok.
- Priebehové okno sa po ukončení nahradí výsledkovým dialógom.
- Výsledkový dialóg používa root Navigator a zobrazí sa pri úspechu aj chybe.
- Ak dialóg nemožno zobraziť, aplikácia použije záložné SnackBar hlásenie a log.
