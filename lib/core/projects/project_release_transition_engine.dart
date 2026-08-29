import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'project_release_profile.dart';

class ProjectReleaseTransitionResult {
  const ProjectReleaseTransitionResult({
    required this.changedFiles,
    required this.targetChannel,
  });

  final List<String> changedFiles;
  final String targetChannel;
}

class ProjectReleaseTransitionEngine {
  const ProjectReleaseTransitionEngine();

  Future<ProjectReleaseTransitionResult> apply({
    required String workspace,
    required ProjectReleaseProfile profile,
    required String targetChannel,
  }) async {
    final target = profile.channel(targetChannel);
    final changed = <String>[];

    Future<void> rewrite(
      String relativePath,
      String Function(String source) transform,
    ) async {
      final file = File(path.join(workspace, relativePath));
      if (!await file.exists()) {
        throw StateError('Transition apply: chýba $relativePath');
      }
      final original = await file.readAsString();
      final updated = transform(original);
      if (updated == original) return;

      final temp = File('${file.path}.transition_tmp');
      if (await temp.exists()) await temp.delete();
      await temp.writeAsString(updated, flush: true);
      await temp.rename(file.path);
      changed.add(relativePath);
    }

    await rewrite('lib/core/app/app_environment.dart', (source) {
      var value = source;
      value = _replaceSingleQuotedConst(value, 'channel', targetChannel);
      value = _replaceSingleQuotedConst(value, 'androidApplicationId', target.androidApplicationId);
      value = _replaceSingleQuotedConst(value, 'androidLabel', target.androidLabel);
      value = _replaceSingleQuotedConst(value, 'dataRootName', target.dataRootName);
      value = _replaceSingleQuotedConst(value, 'databaseName', target.databaseName);
      return value;
    });

    await rewrite('android/app/build.gradle.kts', (source) {
      return source.replaceFirst(
        RegExp(r'applicationId\s*=\s*"[^"]+"'),
        'applicationId = "${target.androidApplicationId}"',
      );
    });

    await rewrite('android/app/src/main/AndroidManifest.xml', (source) {
      return source.replaceFirst(
        RegExp(r'android:label="[^"]+"'),
        'android:label="${target.androidLabel}"',
      );
    });

    // FIX261: Windows native runtime identity follows the same release-profile
    // label as Android. This keeps DEV/FINAL controlled from one profile.
    await rewrite('windows/runner/main.cpp', (source) {
      return source.replaceFirst(
        RegExp(r'window\.Create\(L"[^"]+"'),
        'window.Create(L"${target.androidLabel}"',
      );
    });

    await rewrite('windows/runner/Runner.rc', (source) {
      var value = source;
      value = value.replaceFirst(
        RegExp(r'VALUE "FileDescription", "[^"]*"'),
        'VALUE "FileDescription", "${target.androidLabel}"',
      );
      value = value.replaceFirst(
        RegExp(r'VALUE "ProductName", "[^"]*"'),
        'VALUE "ProductName", "${target.androidLabel}"',
      );
      return value;
    });

    await rewrite(profile.identityFile, (source) {
      return _replaceSingleQuotedConst(source, 'status', target.status);
    });

    await rewrite(ProjectReleaseProfile.relativePath, (source) {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        throw const FormatException('Release profile root nie je JSON objekt.');
      }
      final map = decoded.map((key, value) => MapEntry(key.toString(), value));
      map['activeChannel'] = targetChannel;
      return '${const JsonEncoder.withIndent('  ').convert(map)}\n';
    });

    await verify(
      workspace: workspace,
      profile: profile,
      targetChannel: targetChannel,
    );

    return ProjectReleaseTransitionResult(
      changedFiles: List<String>.unmodifiable(changed),
      targetChannel: targetChannel,
    );
  }

  Future<void> verify({
    required String workspace,
    required ProjectReleaseProfile profile,
    required String targetChannel,
  }) async {
    final target = profile.channel(targetChannel);

    final environment = await File(
      path.join(workspace, 'lib/core/app/app_environment.dart'),
    ).readAsString();
    _requireContains(environment, "static const String channel = '$targetChannel';");
    _requireContains(environment, "static const String androidApplicationId = '${target.androidApplicationId}';");
    _requireContains(environment, "static const String androidLabel = '${target.androidLabel}';");
    _requireContains(environment, "static const String dataRootName = '${target.dataRootName}';");
    _requireContains(environment, "static const String databaseName = '${target.databaseName}';");

    final gradle = await File(
      path.join(workspace, 'android/app/build.gradle.kts'),
    ).readAsString();
    _requireContains(gradle, 'applicationId = "${target.androidApplicationId}"');

    final manifest = await File(
      path.join(workspace, 'android/app/src/main/AndroidManifest.xml'),
    ).readAsString();
    _requireContains(manifest, 'android:label="${target.androidLabel}"');


    final windowsMain = await File(
      path.join(workspace, 'windows/runner/main.cpp'),
    ).readAsString();
    _requireContains(
      windowsMain,
      'window.Create(L"${target.androidLabel}"',
    );

    final windowsRc = await File(
      path.join(workspace, 'windows/runner/Runner.rc'),
    ).readAsString();
    _requireContains(
      windowsRc,
      'VALUE "FileDescription", "${target.androidLabel}"',
    );
    _requireContains(
      windowsRc,
      'VALUE "ProductName", "${target.androidLabel}"',
    );

    final identity = await File(
      path.join(workspace, profile.identityFile),
    ).readAsString();
    _requireContains(identity, "static const String status = '${target.status}';");

    final profileText = await File(
      path.join(workspace, ProjectReleaseProfile.relativePath),
    ).readAsString();
    final decoded = jsonDecode(profileText);
    if (decoded is! Map || decoded['activeChannel']?.toString() != targetChannel) {
      throw StateError('Transition verify: activeChannel nie je $targetChannel.');
    }
  }

  static String _replaceSingleQuotedConst(
    String source,
    String field,
    String value,
  ) {
    final pattern = RegExp("static const String $field\\s*=\\s*'[^']*';");
    if (!pattern.hasMatch(source)) {
      throw StateError('Transition apply: nenašiel sa const $field.');
    }
    return source.replaceFirst(
      pattern,
      "static const String $field = '$value';",
    );
  }

  static void _requireContains(String source, String expected) {
    if (!source.contains(expected)) {
      throw StateError('Transition verify: chýba očakávaná hodnota $expected');
    }
  }
}
