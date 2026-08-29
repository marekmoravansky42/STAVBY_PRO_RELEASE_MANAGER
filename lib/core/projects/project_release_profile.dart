import 'dart:convert';
import 'dart:io';

class ProjectReleaseChannel {
  const ProjectReleaseChannel({
    required this.status,
    required this.androidApplicationId,
    required this.androidLabel,
    required this.dataRootName,
    required this.databaseName,
  });

  final String status;
  final String androidApplicationId;
  final String androidLabel;
  final String dataRootName;
  final String databaseName;

  factory ProjectReleaseChannel.fromJson(Map<String, Object?> json) {
    String requiredText(String key) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isEmpty) {
        throw FormatException('Release profile: chýba $key.');
      }
      return value;
    }

    return ProjectReleaseChannel(
      status: requiredText('status'),
      androidApplicationId: requiredText('androidApplicationId'),
      androidLabel: requiredText('androidLabel'),
      dataRootName: requiredText('dataRootName'),
      databaseName: requiredText('databaseName'),
    );
  }
}


class ProjectReleaseTransitionPlan {
  const ProjectReleaseTransitionPlan({
    required this.fromChannel,
    required this.toChannel,
    required this.from,
    required this.to,
    required this.identityFile,
    required this.configFiles,
  });

  final String fromChannel;
  final String toChannel;
  final ProjectReleaseChannel from;
  final ProjectReleaseChannel to;
  final String identityFile;
  final List<String> configFiles;

  String get summary =>
      '${fromChannel.toUpperCase()} → ${toChannel.toUpperCase()} • '
      '${from.androidApplicationId} → ${to.androidApplicationId} • '
      '${from.dataRootName} → ${to.dataRootName} • '
      '${from.databaseName} → ${to.databaseName}';

  String get previewText => '''
Pred pokračovaním skontroluj plánované zmeny:

Release channel:
  $fromChannel → $toChannel

Android package ID:
  ${from.androidApplicationId}
  → ${to.androidApplicationId}

Názov Android aplikácie:
  ${from.androidLabel}
  → ${to.androidLabel}

Dátový koreň:
  ${from.dataRootName}
  → ${to.dataRootName}

Databáza:
  ${from.databaseName}
  → ${to.databaseName}

Identity súbor:
  $identityFile

Konfiguračné súbory na zálohu:
${configFiles.map((file) => '  • $file').join('\n')}

Po potvrdení sa najprv vytvorí bezpečnostná záloha konfigurácie.
Až potom môže Release Manager vykonať samotný prechod.
''';
}

class ProjectReleaseProfile {
  const ProjectReleaseProfile({
    required this.schemaVersion,
    required this.projectId,
    required this.displayName,
    required this.identityFile,
    required this.activeChannel,
    required this.dev,
    required this.finalChannel,
  });

  final int schemaVersion;
  final String projectId;
  final String displayName;
  final String identityFile;
  final String activeChannel;
  final ProjectReleaseChannel dev;
  final ProjectReleaseChannel finalChannel;

  static const String relativePath =
      'release/stavby_pro_release_profile.json';

  static const List<String> transitionConfigFiles = <String>[
    'release/stavby_pro_release_profile.json',
    'lib/core/app/app_identity.dart',
    'lib/core/app/app_environment.dart',
    'android/app/build.gradle.kts',
    'android/app/src/main/AndroidManifest.xml',
    'windows/runner/main.cpp',
    'windows/runner/Runner.rc',
    'pubspec.yaml',
  ];


  ProjectReleaseChannel channel(String name) {
    switch (name.trim().toLowerCase()) {
      case 'dev':
        return dev;
      case 'final':
        return finalChannel;
      default:
        throw ArgumentError.value(name, 'name', 'Neznámy release channel.');
    }
  }

  ProjectReleaseTransitionPlan planTransition(String targetChannel) {
    final normalizedTarget = targetChannel.trim().toLowerCase();
    final source = channel(activeChannel);
    final target = channel(normalizedTarget);
    return ProjectReleaseTransitionPlan(
      fromChannel: activeChannel,
      toChannel: normalizedTarget,
      from: source,
      to: target,
      identityFile: identityFile,
      configFiles: transitionConfigFiles,
    );
  }

  static Future<ProjectReleaseProfile?> tryLoad(String projectPath) async {
    final normalized = projectPath.replaceAll('\\', '/');
    final separator = normalized.endsWith('/') ? '' : '/';
    final file = File('$normalized$separator$relativePath');
    if (!await file.exists()) return null;

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      throw const FormatException('Release profile nemá JSON objekt.');
    }
    return ProjectReleaseProfile.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  factory ProjectReleaseProfile.fromJson(Map<String, Object?> json) {
    final channelsRaw = json['channels'];
    if (channelsRaw is! Map) {
      throw const FormatException('Release profile: chýba channels.');
    }
    final channels = channelsRaw.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    Map<String, Object?> channelMap(String key) {
      final raw = channels[key];
      if (raw is! Map) {
        throw FormatException('Release profile: chýba channel $key.');
      }
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }

    final projectId = json['projectId']?.toString().trim() ?? '';
    final displayName = json['displayName']?.toString().trim() ?? '';
    final identityFile = json['identityFile']?.toString().trim() ?? '';
    final activeChannel =
        json['activeChannel']?.toString().trim().toLowerCase() ?? '';

    if (projectId.isEmpty || displayName.isEmpty || identityFile.isEmpty) {
      throw const FormatException('Release profile nemá povinnú identitu.');
    }
    if (activeChannel != 'dev' && activeChannel != 'final') {
      throw const FormatException(
        'Release profile activeChannel musí byť dev alebo final.',
      );
    }

    return ProjectReleaseProfile(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      projectId: projectId,
      displayName: displayName,
      identityFile: identityFile,
      activeChannel: activeChannel,
      dev: ProjectReleaseChannel.fromJson(channelMap('dev')),
      finalChannel: ProjectReleaseChannel.fromJson(channelMap('final')),
    );
  }
}
