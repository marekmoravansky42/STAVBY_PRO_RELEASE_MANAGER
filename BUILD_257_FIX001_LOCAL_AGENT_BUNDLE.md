# Release Manager 8.0.0 RC1 Build 257 FIX001 – Local Agent Bundle

Problem:
- Local Agent reported that `tools/release_agent` could not be found.
- The target project path is not necessarily the Release Manager source root.

Fix:
- Confirms and ships the complete `tools/release_agent` directory.
- Local Agent discovery now searches from the running Release Manager executable first.
- It also searches the current process directory and then the selected target project.
- Search depth increased to 12 parent levels.
- Agent validation requires both `pubspec.yaml` and `bin/release_agent.dart`.
- Missing-agent diagnostics now show checked locations.

Build remains 257 because this is an RC1 stabilization FIX.
