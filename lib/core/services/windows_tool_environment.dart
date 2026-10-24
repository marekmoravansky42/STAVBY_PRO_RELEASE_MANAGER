import 'dart:io';

/// Supplies Windows command-line tools with the system paths Flutter needs.
///
/// Some launchers pass Flutter's directory but omit Windows System32 and Git.
/// Flutter then cannot call `where` or read its Git revision during analysis.
Map<String, String> windowsToolEnvironment() {
  final environment = Map<String, String>.from(Platform.environment);
  if (!Platform.isWindows) return environment;

  final systemRoot =
      environment['SystemRoot'] ?? environment['SYSTEMROOT'] ?? r'C:\Windows';
  final programFiles = environment['ProgramFiles'] ?? r'C:\Program Files';
  final requiredPaths = <String>[
    '$systemRoot\\System32',
    systemRoot,
    '$systemRoot\\System32\\WindowsPowerShell\\v1.0',
    '$programFiles\\Git\\cmd',
  ];
  final inheritedPath = environment['PATH'] ?? environment['Path'] ?? '';
  final combined = <String>{
    ...requiredPaths.where((value) => Directory(value).existsSync()),
    ...inheritedPath.split(';').where((value) => value.trim().isNotEmpty),
  };
  environment['PATH'] = combined.join(';');
  return environment;
}
