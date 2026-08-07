/// Lightweight service registry used during the gradual modular migration.
/// It keeps construction centralized without adding a third-party dependency.
class ServiceRegistry {
  ServiceRegistry._();

  static final ServiceRegistry instance = ServiceRegistry._();
  final Map<Type, Object> _services = <Type, Object>{};

  void register<T extends Object>(T service) {
    _services[T] = service;
  }

  T get<T extends Object>() {
    final service = _services[T];
    if (service == null) {
      throw StateError('Service $T is not registered.');
    }
    return service as T;
  }

  bool contains<T extends Object>() => _services.containsKey(T);
  void clear() => _services.clear();
}
