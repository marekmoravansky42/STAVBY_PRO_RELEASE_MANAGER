# DEV001 FIX156 – Current DEV/RC/FINAL release registration

Observed on Build 272:
- One Click Build / Export ZIP succeeded.
- Release Dashboard still selected old LTS BUILD_258_FINAL.
- Release Integrity therefore stayed NEOVERENÉ for the current build.

Root causes:
1. `_createOneClickReleaseZip()` named the export from the workspace folder
   (`Release_Manager`) while Distribution Center searches using the pubspec
   project identity (`stavby_pro_release_manager`). The current export could
   therefore fail the project-token filter.
2. Export created only a ZIP and deleted its staging directory. Distribution
   Center intentionally discovers unpacked release directories containing
   Windows/Android/Reports sections, so the current build had nothing to select.

FIX156:
- package identity now comes from `currentProject.projectName` (pubspec),
- after successful ZIP compression, staging is promoted to a persistent
  unpacked release directory beside the ZIP,
- that directory is immediately registered as `_releaseWizardReleaseDirectory`,
- Distribution Center can discover it on refresh/restart,
- LTS BUILD_258_FINAL remains available as the last FINAL release; a DEV build
  does not overwrite or rename it.

Identity: 8.0.0 RC1 • Build 273 • DEV001 FIX156.
