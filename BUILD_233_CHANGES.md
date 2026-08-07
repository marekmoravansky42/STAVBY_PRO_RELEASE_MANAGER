# STAVBY PRO Release Manager 6.3.6 LTS – Build 233

## Plugin Lifecycle Foundation

- Added `PluginLifecycleManager` for compile-time plugins.
- Added lifecycle states: registered, loaded, started, stopped and failed.
- Added safe start, stop and reload operations.
- Added bulk start/stop operations that isolate plugin failures.
- Added immutable operation result models with captured errors and stack traces.
- Added automated tests for state transitions, reload, registry synchronization and failure isolation.

Dynamic loading of arbitrary Dart code remains disabled. The lifecycle manager only controls plugins compiled into and explicitly registered by the application.
