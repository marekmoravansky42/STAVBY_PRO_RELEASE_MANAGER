# FIX042 – Heartbeat Timer Scope Fix

Corrects FIX041 compile error.

Cause:
`_dashboardAgentHeartbeatTimer?.cancel()` was inserted into the dispose method
of an unrelated preflight dialog State, where that field does not exist.

Fix:
- removed the invalid timer reference from the dialog;
- added timer cancellation to the real `_ReleaseManagerPageState.dispose()`;
- preserves FIX041 Agent latency heartbeat;
- preserves FIX040 startup heartbeat;
- preserves FIX038 non-destructive Workspace Sync.
