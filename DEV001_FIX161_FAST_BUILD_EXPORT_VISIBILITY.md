# DEV001 FIX161 – FAST/FULL build export visibility

The previous Explorer button was added only to the standalone Dashboard
`Export ZIP` action. The user was testing FAST DEV BUILD, so that new UI was
never shown.

FIX161 extends the same visibility to FAST/FULL One Click Build:
- ZIP must physically exist and have non-zero size,
- exact path and size are logged,
- Explorer automatically opens with the ZIP selected after a successful
  FAST/FULL build export,
- the completion dialog shows the exact selectable path,
- its button is now `OTVORIŤ EXPORT ZIP V PRIESKUMNÍKOVI`,
- Last Build keeps a clickable path to the last verified ZIP.

Identity: 8.0.0 RC1 • Build 278 • DEV001 FIX161.
