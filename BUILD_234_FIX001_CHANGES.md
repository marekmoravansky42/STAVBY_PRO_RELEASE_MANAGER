# Build 234 FIX001

Version: 6.3.7+234

## Fixes

- Added the missing `dart:io` import so `FileSystemException` is resolved correctly in `plugin_configuration_manager.dart`.
- Removed the invalid `const` declaration from the non-const `PluginConfigurationSchema` instance in `plugin_configuration_test.dart`.
- Build number remains 234 according to the FIX workflow.
