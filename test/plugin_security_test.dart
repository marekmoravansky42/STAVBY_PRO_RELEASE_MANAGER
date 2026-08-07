import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/plugin_security/plugin_security.dart';

void main() {
  test('default policy denies permissions that were not granted', () {
    const policy = PluginSecurityPolicy(
      granted: <PluginPermission>{PluginPermission.readProject},
    );

    expect(policy.allows(PluginPermission.readProject), isTrue);
    expect(policy.allows(PluginPermission.writeProject), isFalse);
  });

  test('explicit deny takes precedence over grant', () {
    const policy = PluginSecurityPolicy(
      granted: <PluginPermission>{PluginPermission.network},
      denied: <PluginPermission>{PluginPermission.network},
    );

    expect(policy.allows(PluginPermission.network), isFalse);
  });

  test('manager records allowed and denied checks in audit', () {
    final manager = PluginPermissionManager();
    manager.registerPolicy(
      'test.plugin',
      const PluginSecurityPolicy(
        granted: <PluginPermission>{PluginPermission.diagnostics},
      ),
    );

    final allowed = manager.checkPermission(
      'test.plugin',
      PluginPermission.diagnostics,
    );
    final denied = manager.checkPermission(
      'test.plugin',
      PluginPermission.systemCommand,
    );

    expect(allowed.allowed, isTrue);
    expect(denied.allowed, isFalse);
    expect(manager.audit.entries, hasLength(2));
  });

  test('requirePermission throws for unauthorized access', () {
    final manager = PluginPermissionManager();
    manager.registerPolicy('test.plugin', const PluginSecurityPolicy());

    expect(
      () => manager.requirePermission(
        'test.plugin',
        PluginPermission.writeProject,
      ),
      throwsA(isA<PluginSecurityException>()),
    );
  });

  test('validator reports unknown and duplicate permissions', () {
    const validator = PluginPermissionValidator();
    final result = validator.validate(<String>[
      'readProject',
      'readProject',
      'unknownPermission',
    ]);

    expect(result.isValid, isFalse);
    expect(result.permissions, contains(PluginPermission.readProject));
    expect(result.errors, hasLength(2));
  });
}
