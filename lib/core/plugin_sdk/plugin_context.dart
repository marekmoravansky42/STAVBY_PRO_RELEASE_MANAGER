/// Restricted service context passed to plugins during initialization.
class PluginContext {
  PluginContext({Map<Type, Object>? services})
      : _services = Map<Type, Object>.unmodifiable(services ?? const <Type, Object>{});

  final Map<Type, Object> _services;

  bool contains<T extends Object>() => _services.containsKey(T);

  T require<T extends Object>() {
    final service = _services[T];
    if (service == null) {
      throw StateError('Plugin service $T nie je dostupná.');
    }
    return service as T;
  }
}
