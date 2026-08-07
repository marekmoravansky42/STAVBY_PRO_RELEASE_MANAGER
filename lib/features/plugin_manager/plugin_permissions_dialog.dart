import 'package:flutter/material.dart';

import '../../core/plugin_security/plugin_permission.dart';
import '../../core/plugin_security/plugin_permission_group.dart';
import '../../core/plugin_security/plugin_permission_validator.dart';

class PluginPermissionsDialog extends StatelessWidget {
  const PluginPermissionsDialog({
    super.key,
    required this.pluginName,
    required this.permissionNames,
  });

  final String pluginName;
  final List<String> permissionNames;

  static Future<void> show(
    BuildContext context, {
    required String pluginName,
    required List<String> permissionNames,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => PluginPermissionsDialog(
        pluginName: pluginName,
        permissionNames: permissionNames,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validation = const PluginPermissionValidator().validate(
      permissionNames,
    );
    final permissions = validation.permissions;
    final hasElevatedRisk = permissions.any(_isElevatedRisk);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.security_outlined),
          const SizedBox(width: 10),
          Expanded(child: Text('Oprávnenia – $pluginName')),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: permissionNames.isEmpty
            ? const _NoPermissionsMessage()
            : ListView(
                shrinkWrap: true,
                children: [
                  if (hasElevatedRisk) const _RiskWarning(),
                  if (validation.errors.isNotEmpty)
                    _ValidationWarning(errors: validation.errors),
                  for (final group in PluginPermissionGroup.values)
                    if (permissions.intersection(group.permissions).isNotEmpty)
                      _PermissionGroupSection(
                        group: group,
                        permissions: permissions
                            .intersection(group.permissions)
                            .toList(growable: false),
                      ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zavrieť'),
        ),
      ],
    );
  }

  static bool _isElevatedRisk(PluginPermission permission) {
    return switch (permission) {
      PluginPermission.writeProject ||
      PluginPermission.writeConfiguration ||
      PluginPermission.gitWrite ||
      PluginPermission.githubApi ||
      PluginPermission.exportRelease ||
      PluginPermission.fileSystem ||
      PluginPermission.network ||
      PluginPermission.systemCommand => true,
      _ => false,
    };
  }
}

class _NoPermissionsMessage extends StatelessWidget {
  const _NoPermissionsMessage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text('Plugin nepožaduje žiadne osobitné oprávnenia.'),
    );
  }
}

class _RiskWarning extends StatelessWidget {
  const _RiskWarning();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Plugin požaduje jedno alebo viac oprávnení, ktoré môžu meniť projekt, zapisovať súbory, používať sieť alebo spúšťať systémové príkazy.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationWarning extends StatelessWidget {
  const _ValidationWarning({required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manifest obsahuje neplatné oprávnenia',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            for (final error in errors) Text('• $error'),
          ],
        ),
      ),
    );
  }
}

class _PermissionGroupSection extends StatelessWidget {
  const _PermissionGroupSection({
    required this.group,
    required this.permissions,
  });

  final PluginPermissionGroup group;
  final List<PluginPermission> permissions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_groupLabel(group), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final permission in permissions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_permissionIcon(permission)),
              title: Text(_permissionLabel(permission)),
              subtitle: Text(_permissionDescription(permission)),
              trailing: PluginPermissionsDialog._isElevatedRisk(permission)
                  ? const Tooltip(
                      message: 'Zvýšené riziko',
                      child: Icon(Icons.warning_amber_rounded),
                    )
                  : const Icon(Icons.check_circle_outline),
            ),
        ],
      ),
    );
  }

  String _groupLabel(PluginPermissionGroup value) => switch (value) {
        PluginPermissionGroup.project => 'Projekt',
        PluginPermissionGroup.configuration => 'Konfigurácia',
        PluginPermissionGroup.sourceControl => 'Git a sieť',
        PluginPermissionGroup.release => 'Release a súbory',
        PluginPermissionGroup.system => 'Systém a diagnostika',
      };

  IconData _permissionIcon(PluginPermission value) => switch (value) {
        PluginPermission.readProject => Icons.visibility_outlined,
        PluginPermission.writeProject => Icons.edit_outlined,
        PluginPermission.readConfiguration => Icons.settings_outlined,
        PluginPermission.writeConfiguration => Icons.settings_suggest_outlined,
        PluginPermission.gitRead => Icons.download_outlined,
        PluginPermission.gitWrite => Icons.upload_outlined,
        PluginPermission.githubApi => Icons.cloud_outlined,
        PluginPermission.exportRelease => Icons.inventory_2_outlined,
        PluginPermission.fileSystem => Icons.folder_outlined,
        PluginPermission.network => Icons.public_outlined,
        PluginPermission.diagnostics => Icons.monitor_heart_outlined,
        PluginPermission.systemCommand => Icons.terminal_outlined,
      };

  String _permissionLabel(PluginPermission value) => switch (value) {
        PluginPermission.readProject => 'Čítať projekt',
        PluginPermission.writeProject => 'Meniť projekt',
        PluginPermission.readConfiguration => 'Čítať konfiguráciu',
        PluginPermission.writeConfiguration => 'Meniť konfiguráciu',
        PluginPermission.gitRead => 'Čítať údaje Git',
        PluginPermission.gitWrite => 'Zapisovať do Git',
        PluginPermission.githubApi => 'Používať GitHub API',
        PluginPermission.exportRelease => 'Exportovať release',
        PluginPermission.fileSystem => 'Prístup k súborom',
        PluginPermission.network => 'Prístup k sieti',
        PluginPermission.diagnostics => 'Čítať diagnostiku',
        PluginPermission.systemCommand => 'Spúšťať systémové príkazy',
      };

  String _permissionDescription(PluginPermission value) => switch (value) {
        PluginPermission.readProject => 'Môže čítať súbory a údaje aktuálneho projektu.',
        PluginPermission.writeProject => 'Môže meniť súbory a údaje aktuálneho projektu.',
        PluginPermission.readConfiguration => 'Môže čítať nastavenia Release Managera alebo pluginu.',
        PluginPermission.writeConfiguration => 'Môže ukladať a meniť nastavenia.',
        PluginPermission.gitRead => 'Môže čítať stav repozitára a históriu.',
        PluginPermission.gitWrite => 'Môže vytvárať zmeny, commity alebo tagy.',
        PluginPermission.githubApi => 'Môže komunikovať so službou GitHub.',
        PluginPermission.exportRelease => 'Môže vytvárať alebo exportovať release artefakty.',
        PluginPermission.fileSystem => 'Môže pracovať so súbormi mimo vlastného priečinka.',
        PluginPermission.network => 'Môže odosielať a prijímať údaje cez sieť.',
        PluginPermission.diagnostics => 'Môže čítať diagnostické údaje aplikácie.',
        PluginPermission.systemCommand => 'Môže spúšťať príkazy operačného systému.',
      };
}
