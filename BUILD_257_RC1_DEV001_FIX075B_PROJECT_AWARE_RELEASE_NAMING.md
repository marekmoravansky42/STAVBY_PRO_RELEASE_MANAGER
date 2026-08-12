# FIX075B – Project-aware Release Naming

Fixes the hard-coded `STAVBY_PRO_...` directory name in Release Wizard / RC
packaging.

New rule:
`<CURRENT_PROJECT_NAME>_<VERSION>_BUILD_<BUILD>`

Examples:
- Release Manager:
  `STAVBY_PRO_RELEASE_MANAGER_8_0_0_BUILD_257`
- STAVBY PRO:
  `STAVBY_PRO_3_6_..._BUILD_...`

The project token is generated from the currently selected project's real
project name, upper-cased and filesystem-safe.

Also tightens Distribution Center and Release History discovery so neighboring
`STAVBY_PRO_*` releases from another project are no longer accepted merely
because they share the STAVBY_PRO prefix.

Release Manager-specific GitHub updater names are intentionally unchanged,
because those refer to the Release Manager repository/update format itself.
