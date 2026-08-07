import 'package:flutter/material.dart';

import '../../core/plugin_configuration/plugin_configuration_manager.dart';
import '../../core/plugin_configuration/plugin_configuration_schema.dart';

import 'plugin_details_panel.dart';
import 'plugin_manager_controller.dart';
import 'plugin_manager_state.dart';
import 'widgets/plugin_empty_state.dart';
import 'widgets/plugin_list.dart';

class PluginManagerPage extends StatefulWidget {
  const PluginManagerPage({
    super.key,
    this.controller,
    this.configurationManager,
    this.configurationSchemas = const <String, PluginConfigurationSchema>{},
  });

  final PluginManagerController? controller;
  final PluginConfigurationManager? configurationManager;
  final Map<String, PluginConfigurationSchema> configurationSchemas;

  @override
  State<PluginManagerPage> createState() => _PluginManagerPageState();
}

class _PluginManagerPageState extends State<PluginManagerPage> {
  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerChanged);
    widget.controller?.load();
  }

  @override
  void didUpdateWidget(covariant PluginManagerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller?.removeListener(_onControllerChanged);
    widget.controller?.addListener(_onControllerChanged);
    widget.controller?.load();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin Manager'),
        actions: [
          IconButton(
            tooltip: 'Obnoviť',
            onPressed: controller?.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: controller == null
          ? const _PluginManagerNotConfigured()
          : _PluginManagerBody(
              state: controller.state,
              onRefresh: controller.refresh,
              onSelected: controller.selectPlugin,
              onCloseDetails: controller.clearSelection,
              configurationManager: widget.configurationManager,
              configurationSchemas: widget.configurationSchemas,
            ),
    );
  }
}

class _PluginManagerBody extends StatelessWidget {
  const _PluginManagerBody({
    required this.state,
    required this.onRefresh,
    required this.onSelected,
    required this.onCloseDetails,
    required this.configurationManager,
    required this.configurationSchemas,
  });

  final PluginManagerState state;
  final VoidCallback onRefresh;
  final ValueChanged<String> onSelected;
  final VoidCallback onCloseDetails;
  final PluginConfigurationManager? configurationManager;
  final Map<String, PluginConfigurationSchema> configurationSchemas;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading || state.status == PluginManagerLoadStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                'Pluginy sa nepodarilo načítať.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(state.errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Skúsiť znova'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.entries.isEmpty) {
      return PluginEmptyState(onRefresh: onRefresh);
    }

    final selectedEntry = state.selectedEntry;
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSplitView = constraints.maxWidth >= 900;
        final list = PluginList(
          entries: state.entries,
          selectedPluginId: state.selectedPluginId,
          onSelected: onSelected,
        );

        if (!showSplitView) {
          if (selectedEntry != null) {
            return PluginDetailsPanel(
              entry: selectedEntry,
              onClose: onCloseDetails,
              configurationManager: configurationManager,
              configurationSchema:
                  configurationSchemas[selectedEntry.manifest.id],
            );
          }
          return list;
        }

        return Row(
          children: [
            Expanded(flex: 5, child: list),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 4,
              child: selectedEntry == null
                  ? const _SelectPluginHint()
                  : PluginDetailsPanel(
                      entry: selectedEntry,
                      onClose: onCloseDetails,
                      configurationManager: configurationManager,
                      configurationSchema:
                          configurationSchemas[selectedEntry.manifest.id],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SelectPluginHint extends StatelessWidget {
  const _SelectPluginHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Vyber plugin zo zoznamu a zobrazia sa jeho podrobnosti.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PluginManagerNotConfigured extends StatelessWidget {
  const _PluginManagerNotConfigured();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Plugin Manager je pripravený. Discovery služba bude pripojená pri zaradení obrazovky do navigácie.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
