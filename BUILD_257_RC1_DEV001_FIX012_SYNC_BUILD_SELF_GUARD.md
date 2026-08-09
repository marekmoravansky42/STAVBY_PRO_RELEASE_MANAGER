# FIX012 – Sync/Build Race Guard + Self Build Staging

- Workspace Sync cannot start while a build is running.
- One Click Build waits for an active Workspace Sync to finish.
- Windows build rechecks the synchronization lock immediately before linking.
- When Release Manager is building the same EXE it is currently running from,
  the Windows build is performed in an isolated temporary staging workspace.
- The staging Release is copied to `.release_manager/self_build_release`.
- Release ZIP automatically uses that safe staging output.
- The current running Release Manager process is never killed by the lock guard.
- FIX011 dashboard alignment is preserved.
