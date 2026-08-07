import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'pipeline_template.dart';
import 'pipeline_validator.dart';

/// Stores user-defined pipeline templates in one versioned JSON document.
class PipelineStorage {
  PipelineStorage({File? file}) : _fileOverride = file;

  final File? _fileOverride;
  final PipelineValidator _validator = const PipelineValidator();

  File get file {
    if (_fileOverride != null) return _fileOverride;
    final appData = Platform.environment['APPDATA'];
    final base = appData == null || appData.trim().isEmpty
        ? Directory.systemTemp.path
        : appData;
    return File(path.join(
      base,
      'STAVBY_PRO_RELEASE_MANAGER',
      'release_pipeline_templates.json',
    ));
  }

  File get stateFile => File(path.join(
        file.parent.path,
        'release_pipeline_state.json',
      ));

  Future<String?> loadSelectedId() async {
    if (!await stateFile.exists()) return null;
    try {
      final decoded = jsonDecode(await stateFile.readAsString());
      if (decoded is! Map) return null;
      final value = decoded['selectedTemplateId'];
      return value is String && value.trim().isNotEmpty ? value : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSelectedId(String id) async {
    await stateFile.parent.create(recursive: true);
    await stateFile.writeAsString(
      '${jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'selectedTemplateId': id,
        'updatedAt': DateTime.now().toIso8601String(),
      })}\n',
      flush: true,
    );
  }

  Future<List<PipelineTemplate>> load() async {
    if (!await file.exists()) return const <PipelineTemplate>[];
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      throw const FormatException('Súbor pipeline šablón nie je JSON objekt.');
    }
    final rawTemplates = decoded['templates'];
    if (rawTemplates is! List) return const <PipelineTemplate>[];

    final templates = <PipelineTemplate>[];
    for (final item in rawTemplates) {
      if (item is! Map) continue;
      final template = PipelineTemplate.fromJson(
        Map<String, Object?>.from(item),
      );
      _validator.requireValid(template);
      templates.add(template);
    }
    templates.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List<PipelineTemplate>.unmodifiable(templates);
  }

  Future<void> save(Iterable<PipelineTemplate> templates) async {
    final normalized = templates.toList(growable: false);
    for (final template in normalized) {
      _validator.requireValid(template);
    }
    final ids = normalized.map((template) => template.id).toSet();
    if (ids.length != normalized.length) {
      throw const FormatException('Pipeline šablóny obsahujú duplicitné ID.');
    }
    if (normalized.where((template) => template.isDefault).length > 1) {
      throw const FormatException('Predvolená môže byť iba jedna pipeline šablóna.');
    }

    await file.parent.create(recursive: true);
    final document = <String, Object?>{
      'schemaVersion': 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'templates': normalized.map((template) => template.toJson()).toList(),
    };
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(document)}\n',
      flush: true,
    );
  }
}
