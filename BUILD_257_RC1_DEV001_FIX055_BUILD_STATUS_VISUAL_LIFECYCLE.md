# FIX055 – Build Status Visual Lifecycle

Built from FIX054D.

Completes the Dashboard build-state lifecycle visually:
- ČAKÁ = neutral gray;
- PREBIEHA = amber/orange;
- OK = green;
- CHYBA = red.

The `Posledný build` avatar now also changes to PREBIEHA during a new build,
instead of staying green from the previous successful build.

No workflow logic is changed; this is a visual/state consistency follow-up.
