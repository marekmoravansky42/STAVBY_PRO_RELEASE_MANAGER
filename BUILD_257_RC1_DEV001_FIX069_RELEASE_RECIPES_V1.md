# FIX069 – Release Recipes v1

Built from confirmed FIX068.

Adds built-in reusable release recipes to Release Wizard:

- DEV: FAST DEV BUILD (analyze -> test -> Windows -> report -> Release ZIP)
- TEST: FULL BUILD (clean -> pub get -> analyze -> test -> Windows)
- RC: Release Wizard 3.0 full Windows + Android release package
- LTS: Release Wizard 3.0 full stable release workflow

The selected recipe shows its exact workflow before execution.
v1 intentionally reuses already-tested build workflows instead of duplicating
pipeline logic. Custom user-defined recipe persistence is planned for a later
iteration after the built-in recipes are validated.
