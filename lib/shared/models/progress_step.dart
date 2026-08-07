/// Shared state model for Windows, Android and Release Wizard pipelines.
enum ProgressStepState { pending, running, succeeded, failed, skipped }

class ProgressStep {
  const ProgressStep({
    required this.id,
    required this.label,
    this.description,
    this.state = ProgressStepState.pending,
  });

  final String id;
  final String label;
  final String? description;
  final ProgressStepState state;

  ProgressStep copyWith({
    String? label,
    String? description,
    ProgressStepState? state,
  }) {
    return ProgressStep(
      id: id,
      label: label ?? this.label,
      description: description ?? this.description,
      state: state ?? this.state,
    );
  }
}
