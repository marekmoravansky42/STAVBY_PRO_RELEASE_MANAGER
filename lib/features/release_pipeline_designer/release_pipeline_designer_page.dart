import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/project_workspace/project_workspace.dart';
import '../../core/project_workspace/project_platform.dart';
import '../../core/project_workspace/project_workspace_service.dart';

import '../../core/release_pipeline/pipeline_step.dart';
import 'release_pipeline_designer_controller.dart';
import 'release_pipeline_execution_controller.dart';
import 'release_pipeline_execution_panel.dart';

/// Universal visual editor for reusable release pipeline templates.
class ReleasePipelineDesignerPage extends StatefulWidget {
  const ReleasePipelineDesignerPage({
    super.key,
    required this.controller,
    required this.executionController,
    this.workingDirectory,
  });

  final ReleasePipelineDesignerController controller;
  final ReleasePipelineExecutionController executionController;
  final String? workingDirectory;

  @override
  State<ReleasePipelineDesignerPage> createState() =>
      _ReleasePipelineDesignerPageState();
}

class _ReleasePipelineDesignerPageState
    extends State<ReleasePipelineDesignerPage> {
  ProjectWorkspace? _workspace;
  String? _workspaceError;

  Future<void> _selectWorkspace() async {
    final selected = await FilePicker.getDirectoryPath(
      dialogTitle: 'Vyber cieľový Flutter projekt',
    );
    if (selected == null) return;
    try {
      final workspace = await const ProjectWorkspaceService().open(selected);
      if (!mounted) return;
      setState(() {
        _workspace = workspace;
        _workspaceError = null;
      });
      widget.executionController.clearResult();
      await widget.executionController.loadHistory(workspace);
    } catch (error) {
      if (!mounted) return;
      setState(() => _workspaceError = error.toString());
    }
  }
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    widget.executionController.addListener(_refresh);
    if (widget.controller.templates.isEmpty && !widget.controller.loading) {
      widget.controller.load();
    }
  }

  @override
  void didUpdateWidget(covariant ReleasePipelineDesignerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
    if (oldWidget.executionController != widget.executionController) {
      oldWidget.executionController.removeListener(_refresh);
      widget.executionController.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    widget.executionController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final selected = controller.selectedTemplate;

    if (controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Release Pipeline Designer',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Univerzálne pipeline šablóny pre Flutter, Git, export a pluginové kroky.',
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: controller.saving ? null : controller.resetToDefaults,
                icon: const Icon(Icons.restart_alt),
                label: const Text('PREDVOLENÉ'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: controller.saving
                    ? null
                    : () async {
                        final saved = await controller.save();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(saved
                                ? 'Pipeline šablóny boli uložené.'
                                : 'Pipeline sa nepodarilo uložiť.'),
                          ),
                        );
                      },
                icon: controller.saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('ULOŽIŤ'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.folder_open_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('CIEĽOVÝ PROJECT WORKSPACE', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(_workspace == null
                            ? 'Nie je vybraný žiadny cieľový Flutter projekt.'
                            : '${_workspace!.projectName} • ${_workspace!.platforms.map((p) => p.label).join(', ')}'),
                        if (_workspace != null) SelectableText(_workspace!.rootPath, maxLines: 1),
                        if (_workspaceError != null)
                          Text(_workspaceError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: widget.executionController.running ? null : _selectWorkspace,
                    icon: const Icon(Icons.folder_open),
                    label: Text(_workspace == null ? 'VYBRAŤ PROJEKT' : 'ZMENIŤ PROJEKT'),
                  ),
                ],
              ),
            ),
          ),
          if (controller.error != null) ...<Widget>[
            const SizedBox(height: 12),
            MaterialBanner(
              content: Text(controller.error!),
              leading: const Icon(Icons.error_outline),
              actions: <Widget>[
                TextButton(
                  onPressed: controller.load,
                  child: const Text('NAČÍTAŤ ZNOVA'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  width: 270,
                  child: Card(
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(10, 8, 10, 6),
                          child: Text(
                            'PIPELINE ŠABLÓNY',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        for (final template in controller.templates)
                          ListTile(
                            selected: template.id == controller.selectedId,
                            leading: Icon(template.isDefault
                                ? Icons.star_rounded
                                : Icons.account_tree_outlined),
                            title: Text(template.name),
                            subtitle: Text(
                              '${template.steps.where((step) => step.enabled).length} aktívnych z ${template.steps.length} krokov',
                            ),
                            trailing: template.id == controller.selectedId
                                ? const Icon(Icons.check_circle, size: 18)
                                : null,
                            onTap: () => controller.select(template.id),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: selected == null
                        ? const Center(child: Text('Nie je vybraná žiadna pipeline.'))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final useTwoColumns = constraints.maxWidth >= 980;
                              final definition = _PipelineDefinitionPanel(
                                templateName: selected.name,
                                description: selected.description,
                                steps: selected.steps,
                                controller: controller,
                              );
                              final executionPanel =
                                  ReleasePipelineExecutionPanel(
                                controller: widget.executionController,
                                template: selected,
                                workspace: _workspace,
                              );

                              if (!useTwoColumns) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Expanded(child: definition),
                                    const Divider(height: 1),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: executionPanel,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Expanded(flex: 4, child: definition),
                                  const VerticalDivider(width: 1),
                                  Expanded(
                                    flex: 7,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                                      child: executionPanel,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _PipelineDefinitionPanel extends StatelessWidget {
  const _PipelineDefinitionPanel({
    required this.templateName,
    required this.description,
    required this.steps,
    required this.controller,
  });

  final String templateName;
  final String description;
  final List<PipelineStep> steps;
  final ReleasePipelineDesignerController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                templateName,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (description.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(description),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: steps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final step = steps[index];
              return _PipelineStepTile(
                step: step,
                index: index,
                total: steps.length,
                onEnabled: (value) => controller.toggleStep(step.id, value),
                onMoveUp:
                    index == 0 ? null : () => controller.moveStep(step.id, -1),
                onMoveDown: index == steps.length - 1
                    ? null
                    : () => controller.moveStep(step.id, 1),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PipelineStepTile extends StatelessWidget {
  const _PipelineStepTile({
    required this.step,
    required this.index,
    required this.total,
    required this.onEnabled,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final PipelineStep step;
  final int index;
  final int total;
  final ValueChanged<bool> onEnabled;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text(step.title),
        subtitle: Text(step.action),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Switch(value: step.enabled, onChanged: onEnabled),
            IconButton(
              tooltip: 'Posunúť vyššie',
              onPressed: onMoveUp,
              icon: const Icon(Icons.arrow_upward),
            ),
            IconButton(
              tooltip: 'Posunúť nižšie',
              onPressed: onMoveDown,
              icon: const Icon(Icons.arrow_downward),
            ),
          ],
        ),
      ),
    );
  }
}
