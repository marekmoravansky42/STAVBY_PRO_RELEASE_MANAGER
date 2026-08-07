import 'dart:io';

import '../plugin_packages/plugin_package_manager.dart';
import '../plugin_packages/plugin_package_repository.dart';
import '../plugin_packages/plugin_package_result.dart';
import '../plugin_packages/plugin_package_validator.dart';
import 'plugin_installation_transaction.dart';
import 'plugin_rollback_service.dart';

class PluginInstallationEngine {
  PluginInstallationEngine({
    required Directory pluginsDirectory,
    required Directory backupsDirectory,
  })  : _repository = PluginPackageRepository(
          pluginsDirectory: pluginsDirectory,
          backupsDirectory: backupsDirectory,
        ),
        _packageValidator = const PluginPackageValidator(),
        _packageManager = PluginPackageManager(
          repository: PluginPackageRepository(
            pluginsDirectory: pluginsDirectory,
            backupsDirectory: backupsDirectory,
          ),
        );

  final PluginPackageRepository _repository;
  final PluginPackageValidator _packageValidator;
  final PluginPackageManager _packageManager;

  Future<PluginInstallationExecutionResult> installFromDirectory(
    Directory sourceDirectory, {
    String? expectedPluginId,
  }) async {
    final transaction = PluginInstallationTransaction(
      pluginId: sourceDirectory.path.split(Platform.pathSeparator).last,
      sourceDirectory: sourceDirectory,
      startedAt: DateTime.now(),
    )..add('Začína validácia rozbaleného pluginového balíka.');

    try {
      final validation = await _packageValidator.validateDirectory(sourceDirectory);
      if (!validation.isValid || validation.package == null) {
        final message = validation.errors.isEmpty
            ? 'Pluginový balík nie je platný.'
            : validation.errors.join('\n');
        transaction.add('Validácia zlyhala: $message');
        return PluginInstallationExecutionResult(
          packageResult: PluginPackageResult.failed(message: message),
          transaction: transaction,
        );
      }

      final package = validation.package!;
      if (expectedPluginId != null && package.id != expectedPluginId) {
        final message =
            'Vybraný balík má ID ${package.id}, očakáva sa $expectedPluginId.';
        transaction.add('Inštalácia bola zastavená: $message');
        return PluginInstallationExecutionResult(
          packageResult: PluginPackageResult.failed(
            message: message,
            pluginId: package.id,
          ),
          transaction: transaction,
        );
      }

      transaction.add('Validácia balíka bola úspešná.');
      final installed = _repository.pluginDirectory(package.id);
      final isUpdate = await installed.exists();

      if (isUpdate) {
        transaction.add(
          'Existujúca inštalácia bola nájdená; vytvára sa záloha pred aktualizáciou.',
        );
        final rollback = PluginRollbackService(_repository);
        final backup = await rollback.createBackup(
          package.id,
          version: package.version,
        );
        if (backup != null) {
          transaction.add('Záloha bola vytvorená: ${backup.path}');
        }
      }

      final result = isUpdate
          ? await _packageManager.updateFromDirectory(sourceDirectory)
          : await _packageManager.installFromDirectory(sourceDirectory);

      if (result.success) {
        transaction
          ..add(
            isUpdate
                ? 'Súbory pluginu boli bezpečne aktualizované.'
                : 'Súbory pluginu boli skopírované do cieľového adresára.',
          )
          ..add(
            isUpdate
                ? 'Aktualizácia bola úspešne dokončená.'
                : 'Inštalácia bola úspešne dokončená.',
          );
      } else {
        transaction.add(
          isUpdate
              ? 'Aktualizácia zlyhala; pôvodný stav bol automaticky obnovený: ${result.message}'
              : 'Inštalácia bola zastavená: ${result.message}',
        );
      }
      return PluginInstallationExecutionResult(
        packageResult: result,
        transaction: transaction,
      );
    } catch (error, stackTrace) {
      transaction.add('Neočakávaná chyba inštalácie: $error');
      return PluginInstallationExecutionResult(
        packageResult: PluginPackageResult.failed(
          message: 'Inštalácia pluginu zlyhala.',
          error: error,
          stackTrace: stackTrace,
        ),
        transaction: transaction,
      );
    }
  }
}

class PluginInstallationExecutionResult {
  const PluginInstallationExecutionResult({
    required this.packageResult,
    required this.transaction,
  });

  final PluginPackageResult packageResult;
  final PluginInstallationTransaction transaction;

  bool get success => packageResult.success;
}
