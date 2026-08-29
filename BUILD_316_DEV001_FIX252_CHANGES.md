# Build 316 DEV001 FIX252

- Pridaný samostatný DEV/FINAL transition engine.
- Vie meniť iba konfiguračné súbory: AppEnvironment, Android applicationId,
  Android label, AppIdentity status a release profile activeChannel.
- Po zmene vykoná post-write verifikáciu.
- Dáta STAVBY_PRO / STAVBY_PRO_DEV nemení ani nekopíruje.
- Engine zatiaľ nie je automaticky spustený z FULL BUILD.
