# DEV001 FIX176 – Stable release workflow regression guard

No runtime behavior is changed.

After the recent functional fixes and analyzer cleanup, this build adds one
consolidated regression suite for the workflow already confirmed by manual tests:

- FAST DEV exports as DEV and does not auto-open Explorer,
- One Click Release preserves explicit DEV / RC / FINAL naming,
- the physical ZIP gate remains before SHA-256 / Integrity,
- RC / FINAL restore both project recipe and selector to DEV,
- unpacked export cleanup only deletes a directory when its paired ZIP exists,
- Last Export ZIP remains in Project Information.

Identity: Build 293 / DEV001 FIX176.
