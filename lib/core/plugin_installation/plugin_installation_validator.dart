import '../plugin_marketplace/plugin_marketplace_manifest.dart';
import 'plugin_installation_check.dart';
import 'plugin_installation_result.dart';

class PluginInstallationValidator {
  const PluginInstallationValidator({
    required this.currentReleaseManagerVersion,
    required this.supportedApiVersion,
  });

  final String currentReleaseManagerVersion;
  final String supportedApiVersion;

  PluginInstallationValidationResult validate(
    PluginMarketplaceManifest plugin,
  ) {
    final checks = <PluginInstallationCheck>[
      _requiredMetadata(plugin),
      _apiCompatibility(plugin),
      _releaseManagerCompatibility(plugin),
      _downloadUrl(plugin),
      _sha256(plugin),
      _signature(plugin),
      const PluginInstallationCheck(
        title: 'Oprávnenia',
        message: 'Budú overené po stiahnutí a rozbalení plugin.json.',
        status: PluginInstallationCheckStatus.warning,
      ),
    ];

    return PluginInstallationValidationResult(
      pluginId: plugin.id,
      checks: List<PluginInstallationCheck>.unmodifiable(checks),
    );
  }

  PluginInstallationCheck _requiredMetadata(
    PluginMarketplaceManifest plugin,
  ) {
    final valid = <String>[
      plugin.id,
      plugin.name,
      plugin.author,
      plugin.version,
      plugin.apiVersion,
      plugin.minimumReleaseManagerVersion,
    ].every((value) => value.trim().isNotEmpty);
    return PluginInstallationCheck(
      title: 'Manifest',
      message: valid
          ? 'Povinné údaje marketplace manifestu sú vyplnené.'
          : 'Marketplace manifest neobsahuje všetky povinné údaje.',
      status: valid
          ? PluginInstallationCheckStatus.passed
          : PluginInstallationCheckStatus.failed,
    );
  }

  PluginInstallationCheck _apiCompatibility(
    PluginMarketplaceManifest plugin,
  ) {
    final requestedMajor = _major(plugin.apiVersion);
    final supportedMajor = _major(supportedApiVersion);
    final valid = requestedMajor != null && requestedMajor == supportedMajor;
    return PluginInstallationCheck(
      title: 'Plugin API',
      message: valid
          ? 'API ${plugin.apiVersion} je kompatibilné.'
          : 'Plugin vyžaduje API ${plugin.apiVersion}, podporované je $supportedApiVersion.',
      status: valid
          ? PluginInstallationCheckStatus.passed
          : PluginInstallationCheckStatus.failed,
    );
  }

  PluginInstallationCheck _releaseManagerCompatibility(
    PluginMarketplaceManifest plugin,
  ) {
    final minimum = _parseVersion(plugin.minimumReleaseManagerVersion);
    final current = _parseVersion(currentReleaseManagerVersion);
    final valid = minimum != null && current != null && _compare(current, minimum) >= 0;
    return PluginInstallationCheck(
      title: 'Release Manager',
      message: valid
          ? 'Minimálna verzia ${plugin.minimumReleaseManagerVersion} je splnená.'
          : 'Plugin vyžaduje Release Manager ${plugin.minimumReleaseManagerVersion} alebo novší.',
      status: valid
          ? PluginInstallationCheckStatus.passed
          : PluginInstallationCheckStatus.failed,
    );
  }

  PluginInstallationCheck _downloadUrl(PluginMarketplaceManifest plugin) {
    final uri = Uri.tryParse(plugin.downloadUrl);
    final valid = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    return PluginInstallationCheck(
      title: 'Zdroj balíka',
      message: valid
          ? 'Adresa balíka je platná.'
          : 'Download URL nie je platná HTTP/HTTPS adresa.',
      status: valid
          ? PluginInstallationCheckStatus.passed
          : PluginInstallationCheckStatus.failed,
    );
  }

  PluginInstallationCheck _sha256(PluginMarketplaceManifest plugin) {
    final valid = RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(plugin.sha256.trim());
    return PluginInstallationCheck(
      title: 'SHA-256',
      message: valid
          ? 'Kontrolný súčet má platný formát.'
          : 'SHA-256 musí obsahovať presne 64 hexadecimálnych znakov.',
      status: valid
          ? PluginInstallationCheckStatus.passed
          : PluginInstallationCheckStatus.failed,
    );
  }

  PluginInstallationCheck _signature(PluginMarketplaceManifest plugin) {
    final signed = plugin.signature.trim().isNotEmpty;
    return PluginInstallationCheck(
      title: 'Digitálny podpis',
      message: signed
          ? 'Marketplace obsahuje podpis pluginového balíka.'
          : 'Plugin nie je podpísaný; podpisovanie bude povinné v Trust Center.',
      status: signed
          ? PluginInstallationCheckStatus.passed
          : PluginInstallationCheckStatus.warning,
    );
  }

  int? _major(String value) => int.tryParse(value.trim().split('.').first);

  List<int>? _parseVersion(String value) {
    final clean = value.trim().split('+').first;
    final parts = clean.split('.');
    if (parts.isEmpty || parts.length > 3) {
      return null;
    }
    final parsed = parts.map(int.tryParse).toList(growable: false);
    if (parsed.any((item) => item == null)) {
      return null;
    }
    return <int>[
      parsed.isNotEmpty ? parsed[0]! : 0,
      parsed.length > 1 ? parsed[1]! : 0,
      parsed.length > 2 ? parsed[2]! : 0,
    ];
  }

  int _compare(List<int> left, List<int> right) {
    for (var index = 0; index < 3; index++) {
      final result = left[index].compareTo(right[index]);
      if (result != 0) {
        return result;
      }
    }
    return 0;
  }
}
