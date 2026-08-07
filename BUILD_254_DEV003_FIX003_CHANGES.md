# Build 254 DEV003 FIX003 – Agent API Synchronization

- Added shared `AgentApi` endpoint definitions for status, ping and task calls.
- Added protocol version 2 and capability advertisement to Release Agent status.
- Release Manager verifies `flutter_analyze` capability before starting a task.
- Local Agent default port changed from 47831 to 47832 to avoid adopting a stale DEV002 agent.
- Existing incompatible agents are rejected instead of silently reused.
- Task endpoints remain `POST /tasks/analyze` and `GET /tasks/{id}`.
