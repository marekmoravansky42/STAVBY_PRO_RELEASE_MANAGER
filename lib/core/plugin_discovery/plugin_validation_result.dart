/// Result of parsing and validating a plugin manifest.
class PluginValidationResult<T> {
  const PluginValidationResult._({this.value, this.errors = const <String>[]});

  factory PluginValidationResult.valid(T value) =>
      PluginValidationResult<T>._(value: value);

  factory PluginValidationResult.invalid(Iterable<String> errors) =>
      PluginValidationResult<T>._(
        errors: List<String>.unmodifiable(errors),
      );

  final T? value;
  final List<String> errors;

  bool get isValid => value != null && errors.isEmpty;
}
