import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/plugin_installation/plugin_installation.dart';
import '../../core/plugin_marketplace/plugin_marketplace_manifest.dart';
import '../../core/plugin_test_generator/plugin_test_generator.dart';

import 'installed_plugins_view.dart';
import 'plugin_marketplace_controller.dart';
import 'plugin_marketplace_state.dart';
import 'widgets/marketplace_empty_state.dart';
import 'widgets/marketplace_loading.dart';
import 'widgets/marketplace_plugin_tile.dart';
import 'widgets/marketplace_search_bar.dart';

class PluginMarketplacePage extends StatefulWidget {
  const PluginMarketplacePage({
    super.key,
    required this.controller,
    this.currentApiVersion = '',
  });

  final PluginMarketplaceController controller;
  final String currentApiVersion;

  @override
  State<PluginMarketplacePage> createState() => _PluginMarketplacePageState();
}

class _PluginMarketplacePageState extends State<PluginMarketplacePage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.load();
  }

  @override
  void didUpdateWidget(covariant PluginMarketplacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_onChanged);
    widget.controller.addListener(_onChanged);
    widget.controller.load();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin Center'),
          toolbarHeight: 72,
          actions: [
            IconButton(
              tooltip: 'Obnoviť katalóg',
              onPressed: state.isLoading ? null : widget.controller.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.storefront_outlined), text: 'Dostupné'),
              Tab(icon: Icon(Icons.extension_outlined), text: 'Nainštalované'),
              Tab(icon: Icon(Icons.system_update_alt_rounded), text: 'Aktualizácie'),
              Tab(icon: Icon(Icons.settings_outlined), text: 'Nastavenia'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBody(context, state),
            InstalledPluginsView(
              pluginsDirectory: Directory(
                '${Directory.current.path}${Platform.pathSeparator}plugins',
              ),
            ),
            _buildUpdatesTab(context, state),
            _buildSettingsTab(context, state),
          ],
        ),
      ),
    );
  }


  Widget _buildUpdatesTab(
    BuildContext context,
    PluginMarketplaceState state,
  ) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _sectionHeader(
          context,
          icon: Icons.system_update_alt_rounded,
          title: 'Aktualizácie pluginov',
          subtitle:
              'Obnov katalóg a skontroluj dostupné verzie pred inštaláciou.',
          trailing: FilledButton.icon(
            onPressed: state.isLoading ? null : widget.controller.refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Skontrolovať aktualizácie'),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  state.fromCache
                      ? Icons.cloud_off_outlined
                      : Icons.cloud_done_outlined,
                  size: 34,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.fromCache
                            ? 'Používa sa uložený katalóg'
                            : 'Katalóg je aktuálne načítaný',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${state.plugins.length} pluginov v katalógu. '
                        'Nainštalované pluginy môžeš spravovať na karte Nainštalované.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Bezpečný postup aktualizácie'),
            subtitle: Text(
              'Pred aktualizáciou over kompatibilitu API. Release Manager zachová '
              'možnosť rollbacku cez Plugin Installation Engine.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(
    BuildContext context,
    PluginMarketplaceState state,
  ) {
    final pluginsPath =
        '${Directory.current.path}${Platform.pathSeparator}plugins';
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _sectionHeader(
          context,
          icon: Icons.settings_outlined,
          title: 'Nastavenia Plugin Centra',
          subtitle: 'Cesty, katalóg a bezpečnostné informácie na jednom mieste.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Priečinok pluginov',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                SelectableText(pluginsPath),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: Platform.isWindows
                          ? () async {
                              await Process.run(
                                'explorer.exe',
                                <String>[pluginsPath],
                              );
                            }
                          : null,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Otvoriť priečinok'),
                    ),
                    OutlinedButton.icon(
                      onPressed: state.isLoading ? null : widget.controller.refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Obnoviť katalóg'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kompatibilita',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.currentApiVersion.isEmpty
                      ? 'API verzia Release Managera nie je zadaná.'
                      : 'Aktuálna Plugin API verzia: ${widget.currentApiVersion}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(subtitle),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing,
        ],
      ],
    );
  }

  Widget _buildBody(BuildContext context, PluginMarketplaceState state) {
    if (state.status == PluginMarketplaceLoadStatus.initial || state.isLoading) {
      return const MarketplaceLoading();
    }
    if (state.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                state.message.isEmpty
                    ? 'Marketplace sa nepodarilo načítať.'
                    : state.message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: widget.controller.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Skúsiť znova'),
              ),
            ],
          ),
        ),
      );
    }

    final hasFilters = state.query.isNotEmpty || state.selectedCategory != null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MarketplaceSearchBar(
                  value: state.query,
                  onChanged: widget.controller.setQuery,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String>(
                  initialValue: state.selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Kategória',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Všetky kategórie'),
                    ),
                    ...state.categories.map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    ),
                  ],
                  onChanged: widget.controller.setCategory,
                ),
              ),
            ],
          ),
        ),
        if (state.fromCache)
          const MaterialBanner(
            content: Text('Zobrazuje sa lokálne uložený marketplace katalóg.'),
            actions: [SizedBox.shrink()],
          ),
        Expanded(
          child: state.filteredPlugins.isEmpty
              ? MarketplaceEmptyState(
                  hasFilters: hasFilters,
                  onClearFilters: widget.controller.clearFilters,
                  onRefresh: widget.controller.refresh,
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: state.filteredPlugins.length,
                  itemBuilder: (context, index) => MarketplacePluginTile(
                    plugin: state.filteredPlugins[index],
                    currentApiVersion: widget.currentApiVersion,
                    onCreateTestPlugin: () => _createTestPlugin(
                      context,
                      state.filteredPlugins[index],
                    ),
                    onValidateInstallation: () => _showInstallationValidation(
                      context,
                      state.filteredPlugins[index],
                    ),
                    onInstall: () => _installFromDirectory(
                      context,
                      state.filteredPlugins[index],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _createTestPlugin(
    BuildContext context,
    PluginMarketplaceManifest plugin,
  ) async {
    final parentPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'Vyber priečinok, kde sa vytvorí testovací plugin',
      lockParentWindow: true,
    );
    if (parentPath == null || !context.mounted) {
      return;
    }

    const generator = TestPluginGenerator();
    final result = await generator.generate(
      TestPluginGenerationRequest(
        parentDirectory: Directory(parentPath),
        pluginId: plugin.id,
        pluginName: plugin.name,
        author: plugin.author,
        version: plugin.version,
        apiVersion: _normalizeSemanticVersion(plugin.apiVersion),
      ),
    );
    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          result.success
              ? 'Testovací plugin bol vytvorený'
              : 'Plugin sa nepodarilo vytvoriť',
        ),
        content: SizedBox(
          width: 620,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message),
              if (result.pluginDirectory != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Teraz klikni pri rovnakom plugine na „Inštalovať z priečinka“ '
                  'a vyber vytvorený priečinok:',
                ),
                const SizedBox(height: 8),
                SelectableText(result.pluginDirectory!.path),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Zavrieť'),
          ),
        ],
      ),
    );
  }

  String _normalizeSemanticVersion(String value) {
    final parts = value.trim().split('.');
    if (parts.length == 2) {
      return '${parts[0]}.${parts[1]}.0';
    }
    return value.trim();
  }

  Future<void> _installFromDirectory(
    BuildContext context,
    PluginMarketplaceManifest plugin,
  ) async {
    const validator = PluginInstallationValidator(
      currentReleaseManagerVersion: '6.5.2',
      supportedApiVersion: '1.0',
    );
    final validation = validator.validate(plugin);
    if (!validation.isReady) {
      await _showInstallationValidation(context, plugin);
      return;
    }

    final selectedPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'Vyber rozbalený priečinok pluginu ${plugin.name}',
      lockParentWindow: true,
    );
    if (selectedPath == null || !context.mounted) {
      return;
    }

    final engine = PluginInstallationEngine(
      pluginsDirectory: Directory(
        '${Directory.current.path}${Platform.pathSeparator}plugins',
      ),
      backupsDirectory: Directory(
        '${Directory.current.path}${Platform.pathSeparator}plugin_backups',
      ),
    );
    final result = await engine.installFromDirectory(
      Directory(selectedPath),
      expectedPluginId: plugin.id,
    );
    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          result.success
              ? 'Plugin bol nainštalovaný'
              : 'Inštalácia pluginu zlyhala',
        ),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.packageResult.message),
                if (result.packageResult.installedPath != null) ...[
                  const SizedBox(height: 8),
                  SelectableText(
                    'Cieľ: ${result.packageResult.installedPath}',
                  ),
                ],
                const SizedBox(height: 16),
                SelectableText(
                  result.transaction.formatLog(),
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Zavrieť'),
          ),
        ],
      ),
    );

    if (result.success) {
      await widget.controller.refresh();
    }
  }

  Future<void> _showInstallationValidation(
    BuildContext context,
    PluginMarketplaceManifest plugin,
  ) async {
    const validator = PluginInstallationValidator(
      currentReleaseManagerVersion: '6.5.2',
      supportedApiVersion: '1.0',
    );
    final result = validator.validate(plugin);
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          result.isReady
              ? 'Plugin je pripravený na inštaláciu'
              : 'Plugin nie je možné nainštalovať',
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plugin.name),
                const SizedBox(height: 12),
                ...result.checks.map(
                  (check) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      switch (check.status) {
                        PluginInstallationCheckStatus.passed =>
                          Icons.check_circle_outline,
                        PluginInstallationCheckStatus.warning =>
                          Icons.warning_amber_outlined,
                        PluginInstallationCheckStatus.failed =>
                          Icons.error_outline,
                      },
                    ),
                    title: Text(check.title),
                    subtitle: Text(check.message),
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  PluginInstallationLog.format(result),
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Zavrieť'),
          ),
        ],
      ),
    );
  }

}
