import 'plugin_permission.dart';

/// Effective permission policy for one plugin.
class PluginSecurityPolicy {
  const PluginSecurityPolicy({
    this.granted = const <PluginPermission>{},
    this.denied = const <PluginPermission>{},
    this.defaultAllow = false,
  });

  final Set<PluginPermission> granted;
  final Set<PluginPermission> denied;
  final bool defaultAllow;

  bool allows(PluginPermission permission) {
    if (denied.contains(permission)) return false;
    if (granted.contains(permission)) return true;
    return defaultAllow;
  }

  PluginSecurityPolicy copyWith({
    Set<PluginPermission>? granted,
    Set<PluginPermission>? denied,
    bool? defaultAllow,
  }) {
    return PluginSecurityPolicy(
      granted: granted ?? this.granted,
      denied: denied ?? this.denied,
      defaultAllow: defaultAllow ?? this.defaultAllow,
    );
  }
}
