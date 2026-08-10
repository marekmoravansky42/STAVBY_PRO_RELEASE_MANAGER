# FIX054 – Build Status Lifecycle

Built from confirmed FIX053.

Fixes misleading green OK states during a newly started build.

When FAST/FULL BUILD starts:
- Analyze / Test / Windows Build / Export ZIP are reset from the previous build;
- current phase shows PREBIEHA;
- unfinished phases show ČAKÁ;
- each phase turns green OK only after that exact phase succeeds;
- failed phase shows CHYBA;
- the top `Posledný build` status shows PREBIEHA while the pipeline is active.

`Posledné udalosti` uses the same real build lifecycle instead of permanent
green OK labels.
