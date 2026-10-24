import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/release_pipeline/pipeline_executor.dart';
import '../../core/release_pipeline/pipeline_template.dart';
import '../../core/release_pipeline/execution_history_entry.dart';
import '../../core/project_workspace/project_platform.dart';
import '../../app/app_version.dart';
import '../../core/project_workspace/project_workspace.dart';
import 'release_pipeline_execution_controller.dart';

class ReleasePipelineExecutionPanel extends StatefulWidget {
  const ReleasePipelineExecutionPanel({
    super.key,
    required this.controller,
    required this.template,
    required this.workspace,
  });

  final ReleasePipelineExecutionController controller;
  final PipelineTemplate template;
  final ProjectWorkspace? workspace;

  @override
  State<ReleasePipelineExecutionPanel> createState() =>
      _ReleasePipelineExecutionPanelState();
}

class _ReleasePipelineExecutionPanelState
    extends State<ReleasePipelineExecutionPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final template = widget.template;
    final workspace = widget.workspace;
    final report = controller.report;
    final summary = controller.summary;
    final enabledCount = template.steps.where((step) => step.enabled).length;
    final total =
        controller.totalSteps == 0 ? enabledCount : controller.totalSteps;
    final completed = controller.completedSteps;
    final progress = controller.totalSteps == 0 ? 0.0 : controller.progress;
    final active = controller.activeStep;
    final elapsed = controller.elapsed;
    final matchingHistory = controller.history
        .where((entry) => entry.pipelineName == template.name)
        .toList(growable: false);
    final estimatedDuration =
        matchingHistory.isEmpty ? null : matchingHistory.first.duration;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        thickness: 10,
        radius: const Radius.circular(8),
        child: ListView(
          controller: _scrollController,
          primary: false,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 24, 24),
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.dashboard_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Priebeh pipeline',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (!controller.running &&
                    report == null &&
                    estimatedDuration != null)
                  Chip(
                    avatar: const Icon(Icons.timer_outlined, size: 16),
                    label: Text('Odhad ${_formatDuration(estimatedDuration)}'),
                    visualDensity: VisualDensity.compact,
                  ),
                if (report != null)
                  _ResultBadge(
                    succeeded: report.succeeded,
                    cancelled: summary?.cancelledCount != 0,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _DashboardHeader(
              workspace: workspace,
              template: template,
              summary: summary,
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: LinearProgressIndicator(
                    value: controller.running || report != null ? progress : 0,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$completed / $total  •  ${controller.progressPercent} %',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    active != null
                        ? 'Aktuálny krok: ${active.step.title}'
                        : report != null
                            ? 'Pipeline bola dokončená.'
                            : 'Pipeline čaká na spustenie.',
                  ),
                ),
                Text(
                  _formatDuration(elapsed),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (controller.error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(controller.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: controller.running || workspace == null
                      ? null
                      : () async {
                          final success = await controller.run(
                            template: template,
                            workspace: workspace,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Pipeline bola úspešne dokončená.'
                                  : controller.cancelRequested
                                      ? 'Pipeline bola zrušená.'
                                      : 'Pipeline skončila s chybou.'),
                            ),
                          );
                        },
                  icon: controller.running
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(controller.running ? 'PIPELINE BEŽÍ' : 'SPUSTIŤ'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.running && !controller.cancelRequested
                      ? controller.cancel
                      : null,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text(controller.cancelRequested
                      ? 'ZASTAVUJEM...'
                      : 'ZASTAVIŤ'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.running ? null : controller.clearResult,
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: const Text('VYČISTIŤ VÝSLEDOK'),
                ),
                OutlinedButton.icon(
                  onPressed: workspace == null
                      ? null
                      : () => _showHistory(
                            context,
                            controller.history,
                            onClear: () => controller.clearHistory(workspace),
                          ),
                  icon: const Icon(Icons.history),
                  label: Text('HISTÓRIA (${controller.history.length})'),
                ),
              ],
            ),
            if (workspace == null) ...<Widget>[
              const SizedBox(height: 10),
              const Row(
                children: <Widget>[
                  Icon(Icons.info_outline, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Najskôr vyber cieľový projekt. Potom sa aktivuje spustenie pipeline.',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            for (final step in template.steps) ...<Widget>[
              _ExecutionStepCard(
                title: step.title,
                enabled: step.enabled,
                execution: controller.stateFor(step.id),
              ),
              const SizedBox(height: 8),
            ],
            if (summary != null) _PipelineSummary(summary: summary),
          ],
        ),
      ),
    );
  }
}

class _ExecutionStepCard extends StatelessWidget {
  const _ExecutionStepCard({
    required this.title,
    required this.enabled,
    required this.execution,
  });

  final String title;
  final bool enabled;
  final PipelineStepExecution? execution;

  @override
  Widget build(BuildContext context) {
    final status = execution?.status;
    final (icon, color, label) = switch (status) {
      PipelineExecutionStatus.running => (
          Icons.sync_rounded,
          Colors.blue,
          'Beží'
        ),
      PipelineExecutionStatus.succeeded => (
          Icons.check_circle_rounded,
          Colors.green,
          'Hotovo'
        ),
      PipelineExecutionStatus.failed => (
          Icons.error_rounded,
          Theme.of(context).colorScheme.error,
          'Chyba'
        ),
      PipelineExecutionStatus.skipped => (
          Icons.skip_next_rounded,
          Colors.orange,
          'Preskočené'
        ),
      PipelineExecutionStatus.cancelled => (
          Icons.stop_circle_rounded,
          Colors.grey,
          'Zrušené'
        ),
      PipelineExecutionStatus.waiting => (
          Icons.schedule_rounded,
          Colors.grey,
          'Čaká'
        ),
      null when !enabled => (Icons.toggle_off_outlined, Colors.grey, 'Vypnuté'),
      null => (Icons.schedule_rounded, Colors.grey, 'Čaká'),
    };
    final duration = execution?.duration ?? Duration.zero;
    final durationText = duration == Duration.zero
        ? null
        : duration.inSeconds < 1
            ? '${duration.inMilliseconds} ms'
            : '${duration.inSeconds}.${(duration.inMilliseconds % 1000) ~/ 100} s';
    final hasDetails = execution != null &&
        (execution!.log.isNotEmpty ||
            execution!.message.isNotEmpty ||
            execution!.exitCode != null);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
        key: PageStorageKey<String>(
            'pipeline-step-${execution?.step.id ?? title}'),
        initiallyExpanded: status == PipelineExecutionStatus.failed ||
            status == PipelineExecutionStatus.cancelled,
        enabled: hasDetails,
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: _StepOverview(execution: execution),
        trailing: SizedBox(
          width: 88,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800)),
              if (durationText != null) Text(durationText),
            ],
          ),
        ),
        children: hasDetails
            ? <Widget>[
                _StepLogDetails(execution: execution!),
              ]
            : const <Widget>[],
      ),
    );
  }
}

class _StepOverview extends StatelessWidget {
  const _StepOverview({required this.execution});
  final PipelineStepExecution? execution;

  @override
  Widget build(BuildContext context) {
    final value = execution;
    if (value == null) return const SizedBox.shrink();
    final firstError = value.firstErrorLine;
    final latest = value.log.isEmpty ? '' : value.log.last;
    final text =
        firstError ?? (value.message.isNotEmpty ? value.message : latest);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (text.isNotEmpty)
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: firstError == null
                ? null
                : TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (value.log.isNotEmpty)
          Text(
            '${value.logLineCount} riadkov • ${value.warningCount} varovaní • ${value.errorCount} chýb',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _StepLogDetails extends StatelessWidget {
  const _StepLogDetails({required this.execution});
  final PipelineStepExecution execution;

  @override
  Widget build(BuildContext context) {
    final firstError = execution.firstErrorLine;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Divider(),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: <Widget>[
              Text('Exit code: ${execution.exitCode?.toString() ?? '—'}'),
              Text('Log: ${execution.logLineCount} riadkov'),
              Text('Varovania: ${execution.warningCount}'),
              Text('Chyby: ${execution.errorCount}'),
            ],
          ),
          if (firstError != null) ...<Widget>[
            const SizedBox(height: 10),
            Text('Prvý problém',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w800,
                    )),
            const SizedBox(height: 4),
            SelectableText(
              firstError,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
          if (execution.log.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => _showStepLogDialog(context, execution),
                  icon: const Icon(Icons.subject_rounded),
                  label: const Text('ZOBRAZIŤ LOG'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: execution.fullLog));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Log kroku bol skopírovaný.')),
                    );
                  },
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('KOPÍROVAŤ LOG'),
                ),
              ],
            ),
          ] else if (execution.message.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            SelectableText(execution.message),
          ],
        ],
      ),
    );
  }
}

Future<void> _showStepLogDialog(
  BuildContext context,
  PipelineStepExecution execution,
) async {
  final screenSize = MediaQuery.sizeOf(context);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: screenSize.width.clamp(620.0, 1180.0).toDouble(),
        height: (screenSize.height * 0.80).clamp(420.0, 760.0).toDouble(),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Log kroku • ${execution.step.title}',
                style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1220),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      execution.fullLog,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Color(0xFFF8FAFC),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: execution.fullLog),
                      );
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text('Log kroku bol skopírovaný.')),
                      );
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('KOPÍROVAŤ LOG'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('ZAVRIEŤ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) return '$hours:$minutes:$seconds';
  return '$minutes:$seconds';
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.workspace,
    required this.template,
    required this.summary,
  });

  final ProjectWorkspace? workspace;
  final PipelineTemplate template;
  final PipelineExecutionSummary? summary;

  @override
  Widget build(BuildContext context) {
    final platforms = workspace?.platforms.toList()
      ?..sort((a, b) => a.label.compareTo(b.label));
    final lastRun = summary?.finishedAt;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: <Widget>[
              _HeaderValue(
                  label: 'Projekt',
                  value: workspace?.projectName ?? 'Nevybraný'),
              const _HeaderValue(
                  label: 'Release Manager', value: ReleaseManagerVersion.label),
              _HeaderValue(label: 'Pipeline', value: template.name),
              _HeaderValue(
                  label: 'Kroky',
                  value:
                      '${template.steps.where((step) => step.enabled).length} aktívnych'),
              _HeaderValue(
                  label: 'Pluginové kroky',
                  value: '${summary?.pluginCount ?? 0}'),
              _HeaderValue(
                label: 'Posledný beh',
                value: lastRun == null ? '—' : _formatDateTime(lastRun),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Platformy',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (platforms == null || platforms.isEmpty)
            const Text('Nie sú detegované žiadne platformy.')
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: platforms
                  .map((platform) => Chip(
                        visualDensity: VisualDensity.compact,
                        avatar:
                            const Icon(Icons.check_circle_outline, size: 16),
                        label: Text(platform.label),
                      ))
                  .toList(),
            ),
          if (workspace != null) ...<Widget>[
            const SizedBox(height: 8),
            SelectableText(workspace!.rootPath, maxLines: 2),
          ],
        ],
      ),
    );
  }
}

class _HeaderValue extends StatelessWidget {
  const _HeaderValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _PipelineSummary extends StatelessWidget {
  const _PipelineSummary({required this.summary});
  final PipelineExecutionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(summary.succeeded ? Icons.task_alt : Icons.error_outline,
                      color: summary.succeeded
                          ? Colors.green
                          : Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Súhrn pipeline',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  _ResultBadge(
                    succeeded: summary.succeeded,
                    cancelled: summary.cancelledCount > 0,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: <Widget>[
                  Text('Úspešné: ${summary.succeededCount}'),
                  Text('Preskočené: ${summary.skippedCount}'),
                  Text('Chyby: ${summary.failedCount}'),
                  Text('Zrušené: ${summary.cancelledCount}'),
                  Text('Čas: ${_formatDuration(summary.duration)}'),
                  Text('Projekt: ${summary.projectName}'),
                  Text('Pipeline: ${summary.pipelineName}'),
                  Text('Pluginy: ${summary.pluginCount}'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  'Beh: ${summary.runId} • ${_formatDateTime(summary.finishedAt)}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}.${two(value.month)}.${value.year} ${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.succeeded, this.cancelled = false});
  final bool succeeded;
  final bool cancelled;
  @override
  Widget build(BuildContext context) => Text(
        cancelled
            ? 'ZRUŠENÉ'
            : succeeded
                ? 'ÚSPECH'
                : 'CHYBA',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: cancelled
              ? Colors.grey.shade700
              : succeeded
                  ? Colors.green.shade700
                  : Theme.of(context).colorScheme.error,
        ),
      );
}

Future<void> _showHistory(
  BuildContext context,
  List<ExecutionHistoryEntry> entries, {
  Future<void> Function()? onClear,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('História behov pipeline'),
      content: SizedBox(
        width: 720,
        height: 520,
        child: entries.isEmpty
            ? const Center(child: Text('História behov je zatiaľ prázdna.'))
            : ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final color = entry.cancelledCount > 0
                      ? Colors.grey
                      : entry.failedCount > 0
                          ? Theme.of(context).colorScheme.error
                          : Colors.green;
                  return ListTile(
                    leading: Icon(
                        entry.succeeded
                            ? Icons.check_circle
                            : entry.cancelledCount > 0
                                ? Icons.stop_circle
                                : Icons.error,
                        color: color),
                    title: Text('${entry.pipelineName} • ${entry.projectName}'),
                    subtitle: Text(
                        '${_formatDateTime(entry.startedAt)} • ${_formatDuration(entry.duration)}\n'
                        'Hotovo ${entry.succeededCount} • Preskočené ${entry.skippedCount} • Chyby ${entry.failedCount} • Zrušené ${entry.cancelledCount}'),
                    isThreeLine: true,
                    trailing: Chip(label: Text(entry.resultLabel)),
                  );
                },
              ),
      ),
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: entries.isEmpty || onClear == null
              ? null
              : () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (confirmContext) => AlertDialog(
                      title: const Text('Vymazať históriu behov?'),
                      content: const Text(
                        'Vymažú sa iba uložené záznamy pipeline aktuálneho '
                        'workspace. Zdrojové súbory a aktuálny výsledok '
                        'pipeline zostanú zachované.',
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () =>
                              Navigator.of(confirmContext).pop(false),
                          child: const Text('ZRUŠIŤ'),
                        ),
                        FilledButton.icon(
                          onPressed: () =>
                              Navigator.of(confirmContext).pop(true),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('VYMAZAŤ HISTÓRIU'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  await onClear();
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('História behov pipeline bola vymazaná.')),
                  );
                },
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('VYMAZAŤ HISTÓRIU'),
        ),
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ZAVRIEŤ')),
      ],
    ),
  );
}
