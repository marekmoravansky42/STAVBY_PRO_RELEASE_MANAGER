import 'pipeline_step.dart';

/// Named and serializable definition of a complete release workflow.
class PipelineTemplate {
  const PipelineTemplate({
    required this.id,
    required this.name,
    required this.steps,
    this.description = '',
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final List<PipelineStep> steps;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PipelineTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<PipelineStep>? steps,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PipelineTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'description': description,
        'steps': steps.map((step) => step.toJson()).toList(),
        'isDefault': isDefault,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      }..removeWhere((_, value) => value == null);

  factory PipelineTemplate.fromJson(Map<String, Object?> json) {
    DateTime? parseDate(String key) {
      final value = json[key]?.toString().trim();
      return value == null || value.isEmpty ? null : DateTime.tryParse(value);
    }

    final rawSteps = json['steps'];
    final steps = <PipelineStep>[];
    if (rawSteps is List) {
      for (final item in rawSteps) {
        if (item is Map) {
          steps.add(PipelineStep.fromJson(Map<String, Object?>.from(item)));
        }
      }
    }

    return PipelineTemplate(
      id: (json['id']?.toString() ?? '').trim(),
      name: (json['name']?.toString() ?? '').trim(),
      description: (json['description']?.toString() ?? '').trim(),
      steps: List<PipelineStep>.unmodifiable(steps),
      isDefault: json['isDefault'] == true,
      createdAt: parseDate('createdAt'),
      updatedAt: parseDate('updatedAt'),
    );
  }
}
