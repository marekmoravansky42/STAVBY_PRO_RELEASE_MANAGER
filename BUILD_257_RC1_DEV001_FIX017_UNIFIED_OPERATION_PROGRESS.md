# FIX017 – Unified Operation Progress

The existing Dashboard progress area is now shared by work actions.
First integration: Synchronizovať ZIP.

While ZIP synchronization runs, the same Posledný build/activity area shows:
- Synchronizujem ZIP...
- live percentage,
- progress bar,
- current phase: preparation, extraction, identity check, backup, file sync,
  validation, Git/Dashboard refresh.

The button may still disable during execution to prevent double-start, but the
Dashboard now clearly shows that work is active.

FAST/FULL build progress and pipeline step indicators remain unchanged.
This establishes the common progress UI for additional work buttons.
