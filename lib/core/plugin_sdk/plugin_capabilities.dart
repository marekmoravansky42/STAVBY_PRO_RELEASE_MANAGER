/// Capabilities a compiled Release Manager plugin can expose.
enum PluginCapability {
  pipelineStep,
  artifactExporter,
  diagnosticsProvider,
  projectValidator,
  releaseHook,
}

extension PluginCapabilityWireName on PluginCapability {
  String get wireName => switch (this) {
        PluginCapability.pipelineStep => 'pipeline_step',
        PluginCapability.artifactExporter => 'artifact_exporter',
        PluginCapability.diagnosticsProvider => 'diagnostics_provider',
        PluginCapability.projectValidator => 'project_validator',
        PluginCapability.releaseHook => 'release_hook',
      };
}
