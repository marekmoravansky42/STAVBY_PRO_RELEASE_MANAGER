# DEV001 FIX155 – Update ZIP root identity

Observed:
- Delivery ZIP filename correctly identified Build 271 / FIX154.
- The ZIP's first/root directory was still `B257_FAST`.

Audit result:
- `B257_FAST` was not hardcoded in the Release Manager Dart/YAML runtime source.
- It was the stale wrapper directory carried by the development ZIP packaging
  chain itself.

FIX155:
- update package root is now `B272_FAST`,
- runtime identity is Build 272 / DEV001 FIX155,
- all FIX154 Distribution Center / BUILD-number parsing logic remains unchanged.

From this build onward the package wrapper must move with the build number and
must never be copied forward from an older package.
