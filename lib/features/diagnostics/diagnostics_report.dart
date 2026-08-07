/// Nemenné údaje o naposledy vytvorenom diagnostickom reporte.
class DiagnosticsReport {
  const DiagnosticsReport({
    required this.createdAt,
    required this.step,
    required this.content,
    this.savedPath,
  });

  final DateTime createdAt;
  final String step;
  final String content;
  final String? savedPath;

  DiagnosticsReport copyWith({String? savedPath}) => DiagnosticsReport(
        createdAt: createdAt,
        step: step,
        content: content,
        savedPath: savedPath ?? this.savedPath,
      );
}
