# Build 330 / RC1 DEV012 / FIX318

Adds a read-only FINAL publication history browser backed by `.release_manager/final_publications.json`.

- newest receipts first
- version/build/channel, publication timestamp, source tag, GitHub tag and stored online-verification evidence
- open GitHub Release and copy Release/APK URLs from historical receipts
- does not treat persisted evidence as current live online verification
- does not change Publish Gate or publication behavior
