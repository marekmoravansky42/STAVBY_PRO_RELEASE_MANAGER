import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/plugin_runtime/plugin_runtime.dart';

class InstalledPluginsView extends StatefulWidget {
  const InstalledPluginsView({
    super.key,
    required this.pluginsDirectory,
  });

  final Directory pluginsDirectory;

  @override
  State<InstalledPluginsView> createState() => _InstalledPluginsViewState();
}

class _InstalledPluginsViewState extends State<InstalledPluginsView> {
  final InstalledPluginService _service = const InstalledPluginService();
  List<InstalledPluginRecord> _plugins = const <InstalledPluginRecord>[];
  bool _loading = true;
  String _error = '';
  final Set<String> _changing = <String>{};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }
    try {
      final plugins = await _service.load(widget.pluginsDirectory);
      if (!mounted) {
        return;
      }
      setState(() {
        _plugins = plugins;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _setEnabled(
    InstalledPluginRecord plugin,
    bool enabled,
  ) async {
    final id = plugin.manifest.id;
    setState(() => _changing.add(id));
    try {
      await _service.setEnabled(plugin, enabled: enabled);
      await _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stav pluginu sa nepodarilo uložiť: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _changing.remove(id));
      }
    }
  }

  Future<void> _openDirectory(Directory directory) async {
    if (!Platform.isWindows) {
      return;
    }
    await Process.run('explorer.exe', <String>[directory.path]);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: FilledButton.icon(
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
          label: Text('Načítanie zlyhalo – skúsiť znova\n$_error'),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Nainštalované pluginy: ${_plugins.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Obnoviť'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openDirectory(widget.pluginsDirectory),
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Otvoriť priečinok'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _plugins.isEmpty
              ? const Center(
                  child: Text(
                    'Zatiaľ nie je nainštalovaný žiadny plugin.\n'
                    'Plugin nainštaluješ na karte Marketplace.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _plugins.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final plugin = _plugins[index];
                    final changing = _changing.contains(plugin.manifest.id);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              plugin.enabled
                                  ? Icons.extension_rounded
                                  : Icons.extension_off_rounded,
                              size: 34,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plugin.manifest.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(plugin.manifest.id),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Chip(
                                        label: Text(
                                          'Verzia ${plugin.manifest.version}',
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          'API ${plugin.manifest.apiVersion}',
                                        ),
                                      ),
                                      Chip(
                                        avatar: Icon(
                                          plugin.enabled
                                              ? Icons.check_circle_outline
                                              : Icons.pause_circle_outline,
                                          size: 18,
                                        ),
                                        label: Text(
                                          plugin.enabled
                                              ? 'Povolený'
                                              : 'Zakázaný',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    plugin.directory.path,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              children: [
                                Switch(
                                  value: plugin.enabled,
                                  onChanged: changing
                                      ? null
                                      : (value) => _setEnabled(plugin, value),
                                ),
                                IconButton(
                                  tooltip: 'Kopírovať cestu',
                                  onPressed: () => Clipboard.setData(
                                    ClipboardData(text: plugin.directory.path),
                                  ),
                                  icon: const Icon(Icons.copy_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Otvoriť priečinok pluginu',
                                  onPressed: () =>
                                      _openDirectory(plugin.directory),
                                  icon: const Icon(Icons.folder_open_outlined),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
