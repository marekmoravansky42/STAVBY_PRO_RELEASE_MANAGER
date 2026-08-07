/// One declarative step inside a reusable release pipeline template.
class PipelineStep {
  const PipelineStep({
    required this.id,
    required this.title,
    required this.action,
    this.description = '',
    this.enabled = true,
    this.continueOnFailure = false,
    this.parameters = const <String, String>{},
    this.requiredPlatforms = const <String>[],
  });

  final String id;
  final String title;

  /// Stable action identifier resolved by [PipelineExecutor], for example
  /// `flutter_analyze`, `windows_build` or `diagnostics_export`.
  final String action;
  final String description;
  final bool enabled;
  final bool continueOnFailure;
  final Map<String, String> parameters;
  final List<String> requiredPlatforms;

  PipelineStep copyWith({
    String? id,
    String? title,
    String? action,
    String? description,
    bool? enabled,
    bool? continueOnFailure,
    Map<String, String>? parameters,
    List<String>? requiredPlatforms,
  }) {
    return PipelineStep(
      id: id ?? this.id,
      title: title ?? this.title,
      action: action ?? this.action,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      continueOnFailure: continueOnFailure ?? this.continueOnFailure,
      parameters: parameters ?? this.parameters,
      requiredPlatforms: requiredPlatforms ?? this.requiredPlatforms,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'action': action,
        'description': description,
        'enabled': enabled,
        'continueOnFailure': continueOnFailure,
        'parameters': parameters,
        'requiredPlatforms': requiredPlatforms,
      };

  factory PipelineStep.fromJson(Map<String, Object?> json) {
    final rawParameters = json['parameters'];
    final parameters = <String, String>{};
    if (rawParameters is Map) {
      for (final entry in rawParameters.entries) {
        parameters[entry.key.toString()] = entry.value.toString();
      }
    }
    final rawRequiredPlatforms = json['requiredPlatforms'];
    final requiredPlatforms = rawRequiredPlatforms is List
        ? rawRequiredPlatforms.map((item) => item.toString()).toList()
        : const <String>[];
    return PipelineStep(
      id: (json['id']?.toString() ?? '').trim(),
      title: (json['title']?.toString() ?? '').trim(),
      action: (json['action']?.toString() ?? '').trim(),
      description: (json['description']?.toString() ?? '').trim(),
      enabled: json['enabled'] != false,
      continueOnFailure: json['continueOnFailure'] == true,
      parameters: Map<String, String>.unmodifiable(parameters),
      requiredPlatforms: List<String>.unmodifiable(requiredPlatforms),
    );
  }
}
