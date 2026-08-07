typedef AutomatedTestExecutor = Future<String?> Function();

class AutomatedTestDefinition {
  const AutomatedTestDefinition({
    required this.id,
    required this.title,
    required this.execute,
    this.enabled = true,
    this.critical = true,
  });

  final String id;
  final String title;
  final AutomatedTestExecutor execute;
  final bool enabled;
  final bool critical;
}

class AutomatedTestFailure implements Exception {
  const AutomatedTestFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
