import 'dart:convert';
import 'dart:io';

enum BuildCompletionHistoryWrite { appended, duplicate }

String buildCompletionHistoryKey(Map<String, Object?> record) {
  final identity = <String, Object?>{
    'project': record['project'],
    'workspace': record['workspace'],
    'version': record['version'],
    'build': record['build'],
    'stage': record['stage'],
    'releaseType': record['releaseType'],
    'branch': record['branch'],
    'commitMessage': record['commitMessage'],
    'tagName': record['tagName'],
    'options': record['options'],
    'results': record['results'],
  };
  return _canonicalJson(identity);
}

Future<BuildCompletionHistoryWrite> appendBuildCompletionHistory(
  File file,
  Map<String, Object?> completionRecord,
) async {
  var history = <Object?>[];
  if (await file.exists()) {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is List) history = List<Object?>.from(decoded);
  }
  final key = buildCompletionHistoryKey(completionRecord);
  for (final entry in history) {
    if (entry is Map &&
        buildCompletionHistoryKey(Map<String, Object?>.from(entry)) == key) {
      return BuildCompletionHistoryWrite.duplicate;
    }
  }
  history.add(completionRecord);
  if (history.length > 100) history = history.sublist(history.length - 100);
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(history));
  return BuildCompletionHistoryWrite.appended;
}

String _canonicalJson(Object? value) {
  Object? normalize(Object? input) {
    if (input is Map) {
      final entries = input.entries
          .map(
              (entry) => MapEntry(entry.key.toString(), normalize(entry.value)))
          .toList()
        ..sort((left, right) => left.key.compareTo(right.key));
      return <String, Object?>{
        for (final entry in entries) entry.key: entry.value
      };
    }
    if (input is List) return input.map(normalize).toList(growable: false);
    return input;
  }

  return jsonEncode(normalize(value));
}
