import 'pipeline_template.dart';

class PipelineValidationResult {
  const PipelineValidationResult(this.errors);

  final List<String> errors;
  bool get isValid => errors.isEmpty;
}

/// Validates templates before storage or execution.
class PipelineValidator {
  const PipelineValidator();

  PipelineValidationResult validate(PipelineTemplate template) {
    final errors = <String>[];
    if (template.id.trim().isEmpty) errors.add('Pipeline ID nesmie byť prázdne.');
    if (template.name.trim().isEmpty) errors.add('Názov pipeline nesmie byť prázdny.');
    if (template.steps.isEmpty) errors.add('Pipeline musí obsahovať aspoň jeden krok.');

    final ids = <String>{};
    for (final step in template.steps) {
      if (step.id.trim().isEmpty) errors.add('Krok pipeline má prázdne ID.');
      if (step.title.trim().isEmpty) errors.add('Krok ${step.id} nemá názov.');
      if (step.action.trim().isEmpty) errors.add('Krok ${step.id} nemá akciu.');
      if (!ids.add(step.id)) errors.add('Duplicitné ID kroku: ${step.id}.');
    }
    if (!template.steps.any((step) => step.enabled)) {
      errors.add('Pipeline musí mať aspoň jeden zapnutý krok.');
    }
    return PipelineValidationResult(List<String>.unmodifiable(errors));
  }

  void requireValid(PipelineTemplate template) {
    final result = validate(template);
    if (!result.isValid) throw FormatException(result.errors.join('\n'));
  }
}
