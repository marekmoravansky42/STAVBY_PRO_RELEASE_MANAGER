# FIX016 – Running EXE Preflight

- Removed the experimental self-build staging path.
- Before Windows linking, Release Manager checks whether the target EXE is running/locked.
- If the tested Release Manager EXE is still open, the build stops before linker execution.
- A clear message tells the user to close the tested EXE and rerun the build.
- No automatic taskkill is used.
- FIX011 dashboard alignment and FIX013 live pipeline progress remain included.
- Workspace Sync / build mutual exclusion remains included.
