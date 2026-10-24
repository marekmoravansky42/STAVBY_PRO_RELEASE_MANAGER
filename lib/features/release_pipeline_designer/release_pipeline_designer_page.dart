import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/project_workspace/project_workspace.dart';
import '../../core/project_workspace/project_platform.dart';
import '../../core/project_workspace/project_workspace_service.dart';

import '../../core/release_pipeline/pipeline_step.dart';
import '../../core/release_pipeline/default_templates.dart';
import '../../core/release_pipeline/pipeline_step_execution.dart';
import '../../core/release_pipeline/pipeline_template.dart';
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

  Future<void> _openWorkspace(String selected) async {
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

  Future<void> _selectWorkspace() async {
    final selected = await FilePicker.getDirectoryPath(
      dialogTitle: 'Vyber cieľový Flutter projekt',
    );
    if (selected == null) return;
    await _openWorkspace(selected);
  }

  Future<void> _loadCurrentWorkspace() async {
    final workspace = widget.workingDirectory?.trim();
    if (workspace == null || workspace.isEmpty) return;
    await _openWorkspace(workspace);
  }

  Future<void> _runCiProfile(String templateId) async {
    final workspace = _workspace;
    final template = widget.controller.templateById(templateId);
    if (workspace == null ||
        template == null ||
        widget.executionController.running) {
      return;
    }
    widget.controller.select(template.id);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CiRunnerExecutionDialog(
        controller: widget.executionController,
        template: template,
        workspace: workspace,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    widget.executionController.addListener(_refresh);
    if (widget.controller.templates.isEmpty && !widget.controller.loading) {
      widget.controller.load();
    }
    unawaited(_loadCurrentWorkspace());
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
    if (oldWidget.workingDirectory != widget.workingDirectory) {
      unawaited(_loadCurrentWorkspace());
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                onPressed:
                    controller.saving ? null : controller.resetToDefaults,
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
                        const Text('CIEĽOVÝ PROJECT WORKSPACE',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(_workspace == null
                            ? 'Nie je vybraný žiadny cieľový Flutter projekt.'
                            : '${_workspace!.projectName} • ${_workspace!.platforms.map((p) => p.label).join(', ')}'),
                        if (_workspace != null)
                          SelectableText(_workspace!.rootPath, maxLines: 1),
                        if (_workspaceError != null)
                          Text(_workspaceError!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: widget.executionController.running
                        ? null
                        : _selectWorkspace,
                    icon: const Icon(Icons.folder_open),
                    label: Text(_workspace == null
                        ? 'VYBRAŤ PROJEKT'
                        : 'ZMENIŤ PROJEKT'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _LocalCiRunnerCard(
            workspace: _workspace,
            running: widget.executionController.running,
            onRun: _runCiProfile,
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
                        ? const Center(
                            child: Text('Nie je vybraná žiadna pipeline.'))
                        : _PipelineDefinitionPanel(
                            templateName: selected.name,
                            description: selected.description,
                            steps: selected.steps,
                            controller: controller,
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

class _LocalCiRunnerCard extends StatelessWidget {
  const _LocalCiRunnerCard({
    required this.workspace,
    required this.running,
    required this.onRun,
  });

  final ProjectWorkspace? workspace;
  final bool running;
  final Future<void> Function(String templateId) onRun;

  @override
  Widget build(BuildContext context) {
    final enabled = workspace != null && !running;
    const profiles = <({PipelineTemplate template, IconData icon})>[
      (
        template: DefaultPipelineTemplates.ciQuickCheck,
        icon: Icons.speed_rounded,
      ),
      (
        template: DefaultPipelineTemplates.fullRelease,
        icon: Icons.fact_check_rounded,
      ),
      (
        template: DefaultPipelineTemplates.windowsRelease,
        icon: Icons.desktop_windows_rounded,
      ),
      (
        template: DefaultPipelineTemplates.androidRelease,
        icon: Icons.android_rounded,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.precision_manufacturing_rounded),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Lokálny CI Runner',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (running)
                  const Chip(
                    avatar: SizedBox.square(
                      dimension: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    label: Text('BEŽÍ'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Spúšťa vybranú kontrolu iba v aktuálnom workspace. Nevykonáva Git, push ani GitHub Actions.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profiles
                  .map(
                    (profile) => Tooltip(
                      message: profile.template.description,
                      child: OutlinedButton.icon(
                        onPressed:
                            enabled ? () => onRun(profile.template.id) : null,
                        icon: Icon(profile.icon),
                        label: Text(profile.template.name.toUpperCase()),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            if (workspace == null) ...<Widget>[
              const SizedBox(height: 8),
              const Text('Najprv vyber projekt alebo workspace.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _CiRunnerExecutionDialog extends StatefulWidget {
  const _CiRunnerExecutionDialog({
    required this.controller,
    required this.template,
    required this.workspace,
  });

  final ReleasePipelineExecutionController controller;
  final PipelineTemplate template;
  final ProjectWorkspace workspace;

  @override
  State<_CiRunnerExecutionDialog> createState() =>
      _CiRunnerExecutionDialogState();
}

class _CiRunnerExecutionDialogState extends State<_CiRunnerExecutionDialog> {
  var _started = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _started) return;
      _started = true;
      await widget.controller.run(
        template: widget.template,
        workspace: widget.workspace,
      );
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _failureDetails() {
    final report = widget.controller.report;
    final buffer = StringBuffer()
      ..writeln('ŽIADOSŤ PRE CHATGPT/CODEX')
      ..writeln(
        'Analyzuj túto chybu Release Managera, urči príčinu a navrhni jednu minimálnu opravu. '
        'Ak pracuješ v tomto projekte, opravu vykonaj; zachovaj nesúvisiace zmeny a nevytváraj commit, push ani publikovanie.',
      )
      ..writeln()
      ..writeln('CI RUNNER – CHYBA')
      ..writeln('Pipeline: ${widget.template.name}')
      ..writeln('Projekt: ${widget.workspace.projectName}')
      ..writeln('Workspace: ${widget.workspace.rootPath}');
    if (widget.controller.error != null) {
      buffer.writeln('Chyba spustenia: ${widget.controller.error}');
    }
    final failed = report?.steps
            .where((step) => step.status == PipelineExecutionStatus.failed)
            .toList(growable: false) ??
        const <PipelineStepExecution>[];
    for (final step in failed) {
      buffer
        ..writeln()
        ..writeln('Krok: ${step.step.title}')
        ..writeln('Akcia: ${step.step.action}')
        ..writeln('Exit code: ${step.exitCode ?? '—'}');
      if (step.message.isNotEmpty) buffer.writeln(step.message);
      if (step.log.isNotEmpty) {
        buffer
          ..writeln('Výpis:')
          ..writeln(step.log.join('\n'));
      }
    }
    return buffer.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final failed = controller.error != null ||
        (controller.report != null && !controller.report!.succeeded);
    final canClose = !controller.running;
    final screenSize = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        width: (screenSize.width * 0.98).clamp(680.0, 1500.0).toDouble(),
        height: (screenSize.height * 0.96).clamp(520.0, 1040.0).toDouble(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.precision_manufacturing_rounded),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'CI Runner • ${widget.template.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (controller.running)
                    const Chip(label: Text('PREBIEHA'))
                  else if (failed)
                    const Chip(label: Text('CHYBA'))
                  else
                    const Chip(label: Text('HOTOVO')),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ReleasePipelineExecutionPanel(
                  controller: controller,
                  template: widget.template,
                  workspace: widget.workspace,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (failed)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: _failureDetails()),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chyba CI Runnera bola skopírovaná.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_all_outlined),
                      label: const Text('KOPÍROVAŤ CHYBU'),
                    ),
                  FilledButton(
                    onPressed:
                        canClose ? () => Navigator.of(context).pop() : null,
                    child: const Text('ZAVRIEŤ'),
                  ),
                ],
              ),
            ],
          ),
        ),
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
