class ConfigurationCache {
  Map<String, dynamic>? _value;
  Future<Map<String, dynamic>>? _pendingLoad;

  Future<Map<String, dynamic>> load(
    Future<Map<String, dynamic>> Function() loader,
  ) {
    final cached = _value;
    if (cached != null) {
      return Future<Map<String, dynamic>>.value(
        Map<String, dynamic>.from(cached),
      );
    }

    return _pendingLoad ??= loader().then((loaded) {
      _value = Map<String, dynamic>.from(loaded);
      _pendingLoad = null;
      return Map<String, dynamic>.from(loaded);
    }).catchError((Object error, StackTrace stackTrace) {
      _pendingLoad = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  void replace(Map<String, dynamic> value) {
    _value = Map<String, dynamic>.from(value);
    _pendingLoad = null;
  }

  void invalidate() {
    _value = null;
    _pendingLoad = null;
  }
}
