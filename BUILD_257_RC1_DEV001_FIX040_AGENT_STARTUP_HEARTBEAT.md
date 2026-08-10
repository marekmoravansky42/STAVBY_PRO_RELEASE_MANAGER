# FIX040 – Agent Startup Heartbeat

Built directly from confirmed FIX039.

- Dashboard checks localhost Local Agent automatically at application startup.
- Heartbeat repeats every 5 seconds on the standard agent port 47834.
- The user no longer has to open `Vzdialení agenti` first for Dashboard to
  discover an already running Local Agent.
- Remote Agent state from FIX039 is still respected.
- FIX038 non-destructive Workspace Sync remains preserved through FIX039.
