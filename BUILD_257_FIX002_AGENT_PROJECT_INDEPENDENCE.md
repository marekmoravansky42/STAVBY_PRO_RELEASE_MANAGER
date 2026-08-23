# Release Manager 8.0.0 RC1 Build 257 FIX002 – Agent Project Independence

Confirmed problem:
- Local Agent worked only while Release Manager itself was the selected active project.
- Selecting STAVBY PRO removed access to the agent because discovery still depended on project/workspace location.

Fix:
- `tools/release_agent` is now bundled into Flutter assets.
- At runtime Release Manager copies the bundled agent to:
  `%LOCALAPPDATA%/STAVBY_PRO_Release_Manager/release_agent`
- Local Agent starts from that stable writable location.
- Agent discovery no longer uses the selected target project.
- Changing active project to STAVBY PRO or any other Flutter project cannot remove the Local Agent.
- Source-tree discovery remains only as a DEV fallback.

Build remains 257 because this is an RC1 stabilization FIX.
