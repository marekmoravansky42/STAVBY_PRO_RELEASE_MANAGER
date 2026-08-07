import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

class BuildHistoryEntry {
  const BuildHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.platform,
    required this.version,
    required this.build,
    required this.variant,
    required this.projectPath,
    required this.analyzeOk,
    required this.buildOk,
    this.exePath,
    this.exportPath,
  });

  final String id;
  final DateTime createdAt;
  final String platform;
  final String version;
  final int build;
  final String variant;
  final String projectPath;
  final bool analyzeOk;
  final bool buildOk;
  final String? exePath;
  final String? exportPath;

  String get formattedDate {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(createdAt.day)}.${two(createdAt.month)}.${createdAt.year} '
        '${two(createdAt.hour)}:${two(createdAt.minute)}';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'platform': platform,
        'version': version,
        'build': build,
        'variant': variant,
        'projectPath': projectPath,
        'analyzeOk': analyzeOk,
        'buildOk': buildOk,
        'exePath': exePath,
        'exportPath': exportPath,
      };

  factory BuildHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BuildHistoryEntry(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      platform: json['platform'] as String? ?? 'Windows',
      version: json['version'] as String? ?? 'Neznáma',
      build: (json['build'] as num?)?.toInt() ?? 0,
      variant: json['variant'] as String? ?? 'NEURČENÉ',
      projectPath: json['projectPath'] as String? ?? '',
      analyzeOk: json['analyzeOk'] as bool? ?? false,
      buildOk: json['buildOk'] as bool? ?? false,
      exePath: json['exePath'] as String?,
      exportPath: json['exportPath'] as String?,
    );
  }
}

class BuildHistoryService {
  const BuildHistoryService();

  File get _file => File(path.join(
        File(Platform.resolvedExecutable).parent.path,
        'build_history.json',
      ));

  Future<List<BuildHistoryEntry>> load() async {
    if (!await _file.exists()) return const <BuildHistoryEntry>[];
    final raw = await _file.readAsString();
    if (raw.trim().isEmpty) return const <BuildHistoryEntry>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    final entries = decoded
        .whereType<Map<String, dynamic>>()
        .map(BuildHistoryEntry.fromJson)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> add(BuildHistoryEntry entry) async {
    final entries = <BuildHistoryEntry>[entry, ...await load()];
    final unique = <String, BuildHistoryEntry>{};
    for (final item in entries) {
      unique[item.id] = item;
    }
    final trimmed = unique.values.take(100).toList(growable: false);
    await _file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(trimmed.map((e) => e.toJson()).toList()),
      flush: true,
    );
  }

  Future<void> clear() async {
    if (await _file.exists()) await _file.delete();
  }
}
