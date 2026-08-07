class ProjectInfo {
  const ProjectInfo({
    required this.projectName,
    required this.projectPath,
    required this.version,
    required this.build,
  });

  final String projectName;
  final String projectPath;
  final String version;
  final int build;

  String get fullVersion => '$version+$build';

  /// Označenie vývojovej vetvy odvodené z názvu projektového priečinka.
  /// Napr. STAVBY_PRO_3.5.28_DEV_MOBILE_UI_102 -> DEV.
  String get releaseVariant {
    // Kontrolujeme celý názov/cestu projektu, nie iba posledný segment.
    // Takto funguje aj pri ceste typu:
    // C:\6\praca Stavby PRO\STAVBY_PRO_3.5.28_DEV_MOBILE_UI_102
    final source = '${projectPath.replaceAll('\\', '/')}/$projectName'.toUpperCase();

    if (RegExp(r'(^|[/_\-.])DEV([/_\-.]|$)').hasMatch(source)) {
      return 'DEV';
    }
    if (RegExp(r'(^|[/_\-.])BETA([/_\-.]|$)').hasMatch(source)) {
      return 'BETA';
    }

    final rcMatch =
        RegExp(r'(^|[/_\-.])(RC\d*)([/_\-.]|$)').firstMatch(source);
    if (rcMatch != null) {
      return rcMatch.group(2)!;
    }
    return '';
  }

  /// Názov exportovaného Android vydania vychádza priamo z názvu
  /// zdrojového projektového priečinka. Tým sa bez straty zachová napr.
  /// DEV_MOBILE_UI_103.
  String get releaseFileStem {
    final normalized = projectPath.replaceAll('\\', '/');
    final folderName = normalized.split('/').where((part) => part.isNotEmpty).last;
    if (folderName.toUpperCase().startsWith('STAVBY_PRO_')) {
      return folderName;
    }

    // Fallback iba pre netypicky pomenovaný projekt.
    final variant = releaseVariant;
    return variant.isEmpty
        ? 'STAVBY_PRO_${version}_BUILD_$releaseBuild'
        : 'STAVBY_PRO_${version}_${variant}_BUILD_$releaseBuild';
  }

  /// Logické číslo buildu používané OTA Update Centerom.
  ///
  /// STAVBY PRO používa v pubspec.yaml technický build vo formáte
  /// YYYYMMDD + MOBILE_UI build (napr. 2026071983), zatiaľ čo
  /// version.json očakáva iba MOBILE_UI build (napr. 83).
  /// Primárne ho načítame z názvu release priečinka.
  int get releaseBuild {
    // Primárne používame MOBILE_UI číslo z názvu projektového priečinka,
    // napr. STAVBY_PRO_3.5.29_DEV_MOBILE_UI_103 -> 103.
    final match = RegExp(
      r'_MOBILE_UI_(\d+)(?:$|[/\\])',
      caseSensitive: false,
    ).firstMatch(projectPath);
    if (match != null) {
      return int.parse(match.group(1)!);
    }

    // Ak projekt nemá MOBILE_UI v názve, použijeme technický build z pubspec.
    return build;
  }
}
