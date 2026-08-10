# FIX035 – Workspace Recovery + Local Agent

Built directly from confirmed working FIX033.

1. Project Identity Guard now supports one safe recovery case:
   if workspace pubspec.yaml is missing, synchronization is allowed ONLY when
   the incoming ZIP package name exactly matches the packageName saved in
   .release_manager/project_identity_guard.json.
2. This lets Synchronizovať ZIP restore a damaged workspace without disabling
   project identity protection.
3. Local Agent resolves first from:
   <active workspace>/tools/release_agent
4. Obsolete B254 Local Agent message removed.
