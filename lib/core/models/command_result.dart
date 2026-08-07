/// Immutable result returned by command-based services.
class CommandResult {
  const CommandResult({
    required this.executable,
    required this.arguments,
    required this.exitCode,
    required this.standardOutput,
    required this.standardError,
    required this.startedAt,
    required this.finishedAt,
  });

  final String executable;
  final List<String> arguments;
  final int exitCode;
  final String standardOutput;
  final String standardError;
  final DateTime startedAt;
  final DateTime finishedAt;

  bool get succeeded => exitCode == 0;
  Duration get duration => finishedAt.difference(startedAt);

  String get commandLine => <String>[executable, ...arguments].join(' ');
}
