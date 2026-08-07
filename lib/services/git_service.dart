import 'dart:convert';
import 'dart:io';

class GitWorkspaceStatus {
  const GitWorkspaceStatus({required this.path, required this.gitAvailable, required this.isRepository, required this.branch, required this.changedFiles, this.error});
  final String path;
  final bool gitAvailable;
  final bool isRepository;
  final String? branch;
  final List<String> changedFiles;
  final String? error;
  bool get isClean => isRepository && changedFiles.isEmpty;
}


class GitIdentity {
  const GitIdentity({required this.name, required this.email});
  final String name;
  final String email;
  bool get isComplete => name.trim().isNotEmpty && email.trim().isNotEmpty;
}


class GitCommitEntry {
  const GitCommitEntry({
    required this.sha,
    required this.shortSha,
    required this.author,
    required this.date,
    required this.subject,
    required this.tags,
  });
  final String sha;
  final String shortSha;
  final String author;
  final DateTime? date;
  final String subject;
  final List<String> tags;
}



class GitDiffFileEntry {
  const GitDiffFileEntry({
    required this.path,
    required this.additions,
    required this.deletions,
    required this.isBinary,
  });
  final String path;
  final int additions;
  final int deletions;
  final bool isBinary;
}

class GitDiffResult {
  const GitDiffResult({
    required this.commitSha,
    required this.parentSha,
    required this.files,
  });
  final String commitSha;
  final String? parentSha;
  final List<GitDiffFileEntry> files;
  int get additions => files.fold(0, (sum, item) => sum + item.additions);
  int get deletions => files.fold(0, (sum, item) => sum + item.deletions);
}

class GitOperationResult {
  const GitOperationResult({required this.success, required this.message});
  final bool success;
  final String message;
}


class GitBuildPublishResult {
  const GitBuildPublishResult({
    required this.success,
    required this.message,
    this.commitSha,
    this.tagName,
    this.branch,
  });

  final bool success;
  final String message;
  final String? commitSha;
  final String? tagName;
  final String? branch;
}

class GitService {
  const GitService();


  Future<GitIdentity> readIdentity(String workspacePath) async {
    Future<String> read(String key) async {
      final local = await Process.run('git', ['config', '--local', '--get', key], workingDirectory: workspacePath, runInShell: true);
      if (local.exitCode == 0 && local.stdout.toString().trim().isNotEmpty) return local.stdout.toString().trim();
      final global = await Process.run('git', ['config', '--global', '--get', key], workingDirectory: workspacePath, runInShell: true);
      return global.exitCode == 0 ? global.stdout.toString().trim() : '';
    }
    return GitIdentity(name: await read('user.name'), email: await read('user.email'));
  }

  Future<GitOperationResult> saveIdentity(String workspacePath, {required String name, required String email, required bool global}) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim();
    if (normalizedName.isEmpty || normalizedEmail.isEmpty) {
      return const GitOperationResult(success: false, message: 'Meno a e-mail autora sú povinné.');
    }
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(normalizedEmail)) {
      return const GitOperationResult(success: false, message: 'Zadaj platnú e-mailovú adresu autora.');
    }
    final scope = global ? '--global' : '--local';
    for (final entry in <MapEntry<String, String>>[MapEntry('user.name', normalizedName), MapEntry('user.email', normalizedEmail)]) {
      final result = await Process.run('git', ['config', scope, entry.key, entry.value], workingDirectory: workspacePath, runInShell: true);
      if (result.exitCode != 0) return GitOperationResult(success: false, message: 'Git identitu sa nepodarilo uložiť: ${result.stderr.toString().trim()}');
    }
    return GitOperationResult(success: true, message: global ? 'Git identita bola uložená pre celý počítač.' : 'Git identita bola uložená pre tento projekt.');
  }

  Future<GitOperationResult> ensureFlutterGitignore(String workspacePath) async {
    final file = File('$workspacePath${Platform.pathSeparator}.gitignore');
    if (await file.exists()) {
      return const GitOperationResult(success: true, message: '.gitignore už existuje a zostal zachovaný.');
    }
    const contents = '''# Flutter / Dart
.dart_tool/
.packages
.pub-cache/
build/
.flutter-plugins
.flutter-plugins-dependencies

# Generated platform files
android/.gradle/
android/local.properties
android/**/GeneratedPluginRegistrant.java
ios/Flutter/ephemeral/
linux/flutter/ephemeral/
macos/Flutter/ephemeral/
windows/flutter/ephemeral/

# IDE and operating system
.idea/
.vscode/
.vs/
*.iml
.DS_Store
Thumbs.db

# Logs and temporary files
*.log
*.tmp
*.bak
''';
    await file.writeAsString(contents, flush: true);
    return const GitOperationResult(success: true, message: 'Bol vytvorený odporúčaný .gitignore pre Flutter projekt.');
  }

  Future<GitOperationResult> initializeRepository(
    String workspacePath, {
    String initialBranch = 'dev',
  }) async {
    final directory = Directory(workspacePath);
    if (!await directory.exists()) {
      return const GitOperationResult(
        success: false,
        message: 'Vybraný pracovný priečinok neexistuje.',
      );
    }

    try {
      final version = await Process.run(
        'git',
        const ['--version'],
        runInShell: true,
      );
      if (version.exitCode != 0) {
        return const GitOperationResult(
          success: false,
          message: 'Git nie je dostupný v systémovej premennej PATH.',
        );
      }

      final existing = await Process.run(
        'git',
        const ['rev-parse', '--is-inside-work-tree'],
        workingDirectory: workspacePath,
        runInShell: true,
      );
      if (existing.exitCode == 0 && existing.stdout.toString().trim() == 'true') {
        return const GitOperationResult(
          success: true,
          message: 'Priečinok už je Git repozitár.',
        );
      }

      var init = await Process.run(
        'git',
        ['init', '-b', initialBranch],
        workingDirectory: workspacePath,
        runInShell: true,
      );

      // Staršie verzie Git nemusia podporovať parameter -b.
      if (init.exitCode != 0) {
        init = await Process.run(
          'git',
          const ['init'],
          workingDirectory: workspacePath,
          runInShell: true,
        );
        if (init.exitCode == 0) {
          final branch = await Process.run(
            'git',
            ['checkout', '-b', initialBranch],
            workingDirectory: workspacePath,
            runInShell: true,
          );
          if (branch.exitCode != 0) {
            return GitOperationResult(
              success: false,
              message: 'Repozitár bol inicializovaný, ale vetvu $initialBranch sa nepodarilo vytvoriť: ${branch.stderr.toString().trim()}',
            );
          }
        }
      }

      if (init.exitCode != 0) {
        return GitOperationResult(
          success: false,
          message: 'Inicializácia Git repozitára zlyhala: ${init.stderr.toString().trim()}',
        );
      }

      return GitOperationResult(
        success: true,
        message: 'Git repozitár bol inicializovaný s vetvou $initialBranch.',
      );
    } on ProcessException catch (e) {
      return GitOperationResult(
        success: false,
        message: 'Git sa nepodarilo spustiť: ${e.message}',
      );
    } catch (e) {
      return GitOperationResult(
        success: false,
        message: 'Inicializácia Git repozitára zlyhala: $e',
      );
    }
  }


  Future<GitOperationResult> commitAll(
    String workspacePath, {
    required String message,
  }) async {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      return const GitOperationResult(
        success: false,
        message: 'Správa commitu nesmie byť prázdna.',
      );
    }
    if (!await Directory(workspacePath).exists()) {
      return const GitOperationResult(
        success: false,
        message: 'Vybraný pracovný priečinok neexistuje.',
      );
    }

    try {
      final repository = await Process.run(
        'git',
        const ['rev-parse', '--is-inside-work-tree'],
        workingDirectory: workspacePath,
        runInShell: true,
      );
      if (repository.exitCode != 0 ||
          repository.stdout.toString().trim() != 'true') {
        return const GitOperationResult(
          success: false,
          message: 'Vybraný priečinok nie je Git repozitár.',
        );
      }

      final status = await Process.run(
        'git',
        const ['status', '--porcelain'],
        workingDirectory: workspacePath,
        runInShell: true,
      );
      if (status.exitCode != 0) {
        return GitOperationResult(
          success: false,
          message: 'Git stav sa nepodarilo načítať: ${status.stderr.toString().trim()}',
        );
      }
      if (status.stdout.toString().trim().isEmpty) {
        return const GitOperationResult(
          success: false,
          message: 'Nie sú dostupné žiadne zmeny na commit.',
        );
      }

      final add = await Process.run(
        'git',
        const ['add', '--all'],
        workingDirectory: workspacePath,
        runInShell: true,
      );
      if (add.exitCode != 0) {
        return GitOperationResult(
          success: false,
          message: 'Pridanie súborov do commitu zlyhalo: ${add.stderr.toString().trim()}',
        );
      }

      final commit = await Process.run(
        'git',
        ['commit', '-m', normalizedMessage],
        workingDirectory: workspacePath,
        runInShell: true,
      );
      if (commit.exitCode != 0) {
        final details = commit.stderr.toString().trim().isNotEmpty
            ? commit.stderr.toString().trim()
            : commit.stdout.toString().trim();
        return GitOperationResult(
          success: false,
          message: 'Commit sa nepodarilo vytvoriť: $details',
        );
      }

      final firstLine = normalizedMessage.split(RegExp(r'\r?\n')).first;
      return GitOperationResult(
        success: true,
        message: 'Commit „$firstLine“ bol úspešne vytvorený.',
      );
    } on ProcessException catch (e) {
      return GitOperationResult(
        success: false,
        message: 'Git sa nepodarilo spustiť: ${e.message}',
      );
    } catch (e) {
      return GitOperationResult(
        success: false,
        message: 'Vytvorenie commitu zlyhalo: $e',
      );
    }
  }


  Future<List<GitCommitEntry>> history(String workspacePath, {int limit = 40}) async {
    if (!await Directory(workspacePath).exists()) return const <GitCommitEntry>[];
    try {
      const separator = r'%x1f';
      const recordSeparator = r'%x1e';
      final result = await Process.run(
        'git',
        <String>[
          'log',
          '--date=iso-strict',
          '--decorate=short',
          '--pretty=format:%H$separator%h$separator%an$separator%ad$separator%s$separator%D$recordSeparator',
          '-n',
          '$limit',
        ],
        workingDirectory: workspacePath,
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (result.exitCode != 0) return const <GitCommitEntry>[];
      return (result.stdout as String)
          .split(String.fromCharCode(0x1e))
          .map((record) => record.trim())
          .where((record) => record.isNotEmpty)
          .map((record) {
            final fields = record.split(String.fromCharCode(0x1f));
            if (fields.length < 6) return null;
            final decorations = fields[5]
                .split(',')
                .map((value) => value.trim())
                .where((value) => value.startsWith('tag: '))
                .map((value) => value.substring(5).trim())
                .toList(growable: false);
            return GitCommitEntry(
              sha: fields[0],
              shortSha: fields[1],
              author: fields[2],
              date: DateTime.tryParse(fields[3]),
              subject: fields[4],
              tags: decorations,
            );
          })
          .whereType<GitCommitEntry>()
          .toList(growable: false);
    } catch (_) {
      return const <GitCommitEntry>[];
    }
  }

  Future<GitDiffResult?> diffWithParent(
    String workspacePath, {
    required String commitSha,
  }) async {
    final normalizedSha = commitSha.trim();
    if (normalizedSha.isEmpty || !await Directory(workspacePath).exists()) return null;
    try {
      final parentResult = await Process.run(
        'git',
        <String>['rev-parse', '$normalizedSha^'],
        workingDirectory: workspacePath,
        runInShell: true,
      );
      final parentSha = parentResult.exitCode == 0 ? parentResult.stdout.toString().trim() : null;
      final args = parentSha == null || parentSha.isEmpty
          ? <String>['diff-tree', '--root', '--no-commit-id', '--numstat', '-r', normalizedSha]
          : <String>['diff', '--numstat', parentSha, normalizedSha];
      final result = await Process.run(
        'git',
        args,
        workingDirectory: workspacePath,
        runInShell: true,
      );
      if (result.exitCode != 0) return null;
      final files = <GitDiffFileEntry>[];
      for (final line in result.stdout.toString().split(RegExp(r'\r?\n'))) {
        if (line.trim().isEmpty) continue;
        final fields = line.split('\t');
        if (fields.length < 3) continue;
        final binary = fields[0] == '-' || fields[1] == '-';
        files.add(GitDiffFileEntry(
          path: fields.sublist(2).join('\t'),
          additions: binary ? 0 : int.tryParse(fields[0]) ?? 0,
          deletions: binary ? 0 : int.tryParse(fields[1]) ?? 0,
          isBinary: binary,
        ));
      }
      return GitDiffResult(
        commitSha: normalizedSha,
        parentSha: parentSha?.isEmpty == true ? null : parentSha,
        files: files,
      );
    } catch (_) {
      return null;
    }
  }

  Future<GitOperationResult> createTag(
    String workspacePath, {
    required String tagName,
    String? message,
  }) async {
    final normalized = tagName.trim();
    if (normalized.isEmpty) {
      return const GitOperationResult(success: false, message: 'Názov tagu nesmie byť prázdny.');
    }
    if (!RegExp(r'^[A-Za-z0-9._/-]+$').hasMatch(normalized) || normalized.startsWith('-') || normalized.endsWith('/') || normalized.contains('..')) {
      return const GitOperationResult(success: false, message: 'Názov tagu obsahuje nepovolené znaky.');
    }
    try {
      final existing = await Process.run('git', <String>['tag', '--list', normalized], workingDirectory: workspacePath, runInShell: true);
      if (existing.exitCode == 0 && existing.stdout.toString().trim().isNotEmpty) {
        return GitOperationResult(success: false, message: 'Tag „$normalized“ už existuje.');
      }
      final args = <String>['tag'];
      final note = message?.trim() ?? '';
      if (note.isNotEmpty) {
        args.addAll(<String>['-a', normalized, '-m', note]);
      } else {
        args.add(normalized);
      }
      final result = await Process.run('git', args, workingDirectory: workspacePath, runInShell: true);
      if (result.exitCode != 0) {
        final details = result.stderr.toString().trim().isNotEmpty ? result.stderr.toString().trim() : result.stdout.toString().trim();
        return GitOperationResult(success: false, message: 'Tag sa nepodarilo vytvoriť: $details');
      }
      return GitOperationResult(success: true, message: 'Tag „$normalized“ bol úspešne vytvorený.');
    } catch (e) {
      return GitOperationResult(success: false, message: 'Vytvorenie tagu zlyhalo: $e');
    }
  }

  Future<String?> currentBranch(String workspacePath) async {
    try {
      final result = await Process.run(
        'git',
        const <String>['branch', '--show-current'],
        workingDirectory: workspacePath,
        runInShell: true,
      );
      if (result.exitCode != 0) return null;
      final branch = result.stdout.toString().trim();
      return branch.isEmpty ? null : branch;
    } catch (_) {
      return null;
    }
  }

  Future<GitBuildPublishResult> publishBuild(
    String workspacePath, {
    required String commitMessage,
    required String tagName,
    String remoteName = 'origin',
    String requiredBranch = '',
  }) async {
    final message = commitMessage.trim();
    final tag = tagName.trim();
    if (message.isEmpty) {
      return const GitBuildPublishResult(success: false, message: 'Správa commitu nesmie byť prázdna.');
    }
    if (tag.isEmpty || !RegExp(r'^[A-Za-z0-9._/-]+$').hasMatch(tag)) {
      return const GitBuildPublishResult(success: false, message: 'Tag je prázdny alebo obsahuje nepovolené znaky.');
    }
    if (!await Directory(workspacePath).exists()) {
      return const GitBuildPublishResult(success: false, message: 'Vybraný pracovný priečinok neexistuje.');
    }

    String output(ProcessResult result) {
      final error = result.stderr.toString().trim();
      return error.isNotEmpty ? error : result.stdout.toString().trim();
    }

    try {
      final repo = await Process.run('git', const ['rev-parse', '--is-inside-work-tree'], workingDirectory: workspacePath, runInShell: true);
      if (repo.exitCode != 0 || repo.stdout.toString().trim() != 'true') {
        return const GitBuildPublishResult(success: false, message: 'Vybraný priečinok nie je Git repozitár.');
      }

      final branchResult = await Process.run('git', const ['branch', '--show-current'], workingDirectory: workspacePath, runInShell: true);
      final branch = branchResult.stdout.toString().trim();
      if (branchResult.exitCode != 0 || branch.isEmpty) {
        return GitBuildPublishResult(success: false, message: 'Aktuálnu Git vetvu sa nepodarilo zistiť: ${output(branchResult)}');
      }
      if (requiredBranch.trim().isNotEmpty && branch != requiredBranch.trim()) {
        return GitBuildPublishResult(
          success: false,
          branch: branch,
          message: 'Build sa neuložil. Aktívna vetva je „$branch“, požadovaná je „${requiredBranch.trim()}“.',
        );
      }

      final remoteResult = await Process.run('git', <String>['remote', 'get-url', remoteName], workingDirectory: workspacePath, runInShell: true);
      final hasRemote = remoteResult.exitCode == 0 && remoteResult.stdout.toString().trim().isNotEmpty;

      final status = await Process.run('git', const ['status', '--porcelain'], workingDirectory: workspacePath, runInShell: true);
      if (status.exitCode != 0) {
        return GitBuildPublishResult(success: false, branch: branch, message: 'Git stav sa nepodarilo načítať: ${output(status)}');
      }
      if (status.stdout.toString().trim().isEmpty) {
        return GitBuildPublishResult(success: false, branch: branch, message: 'Nie sú žiadne zmeny na uloženie. Working tree je čistý.');
      }

      final localTag = await Process.run('git', <String>['tag', '--list', tag], workingDirectory: workspacePath, runInShell: true);
      if (localTag.exitCode == 0 && localTag.stdout.toString().trim().isNotEmpty) {
        return GitBuildPublishResult(success: false, branch: branch, tagName: tag, message: 'Tag „$tag“ už existuje lokálne. Použi nový build/tag alebo starý tag najprv vedome odstráň.');
      }
      if (hasRemote) {
        final remoteTag = await Process.run('git', <String>['ls-remote', '--exit-code', '--tags', remoteName, 'refs/tags/$tag'], workingDirectory: workspacePath, runInShell: true);
        if (remoteTag.exitCode == 0 && remoteTag.stdout.toString().trim().isNotEmpty) {
          return GitBuildPublishResult(success: false, branch: branch, tagName: tag, message: 'Tag „$tag“ už existuje na vzdialenom repozitári. Nebol prepísaný.');
        }
      }

      final add = await Process.run('git', const ['add', '--all'], workingDirectory: workspacePath, runInShell: true);
      if (add.exitCode != 0) {
        return GitBuildPublishResult(success: false, branch: branch, message: 'Git add zlyhal: ${output(add)}');
      }

      final commit = await Process.run('git', <String>['commit', '-m', message], workingDirectory: workspacePath, runInShell: true);
      if (commit.exitCode != 0) {
        return GitBuildPublishResult(success: false, branch: branch, message: 'Commit zlyhal: ${output(commit)}');
      }

      final shaResult = await Process.run('git', const ['rev-parse', '--short', 'HEAD'], workingDirectory: workspacePath, runInShell: true);
      final sha = shaResult.exitCode == 0 ? shaResult.stdout.toString().trim() : null;

      final createTag = await Process.run('git', <String>['tag', '-a', tag, '-m', message], workingDirectory: workspacePath, runInShell: true);
      if (createTag.exitCode != 0) {
        return GitBuildPublishResult(success: false, branch: branch, commitSha: sha, tagName: tag, message: 'Commit bol vytvorený${sha == null ? '' : ' ($sha)'}, ale tag zlyhal: ${output(createTag)}');
      }

      if (!hasRemote) {
        return GitBuildPublishResult(
          success: true,
          branch: branch,
          commitSha: sha,
          tagName: tag,
          message: 'Build bol úspešne uložený lokálne do Gitu. Vzdialený repozitár „$remoteName“ nie je nastavený, preto bol push preskočený. Commit: ${sha ?? 'vytvorený'} • Tag: $tag',
        );
      }

      final pushBranch = await Process.run('git', <String>['push', '-u', remoteName, branch], workingDirectory: workspacePath, runInShell: true);
      if (pushBranch.exitCode != 0) {
        return GitBuildPublishResult(success: false, branch: branch, commitSha: sha, tagName: tag, message: 'Commit a tag boli vytvorené lokálne, ale push vetvy zlyhal: ${output(pushBranch)}');
      }

      final pushTag = await Process.run('git', <String>['push', remoteName, tag], workingDirectory: workspacePath, runInShell: true);
      if (pushTag.exitCode != 0) {
        return GitBuildPublishResult(success: false, branch: branch, commitSha: sha, tagName: tag, message: 'Vetva bola odoslaná, ale push tagu zlyhal: ${output(pushTag)}');
      }

      return GitBuildPublishResult(
        success: true,
        branch: branch,
        commitSha: sha,
        tagName: tag,
        message: 'Build bol úspešne uložený do Gitu a odoslaný na $remoteName. Commit: ${sha ?? 'vytvorený'} • Tag: $tag',
      );
    } on ProcessException catch (error) {
      return GitBuildPublishResult(success: false, message: 'Git sa nepodarilo spustiť: ${error.message}');
    } catch (error) {
      return GitBuildPublishResult(success: false, message: 'Uloženie buildu do Gitu zlyhalo: $error');
    }
  }


  Future<GitOperationResult> restoreCommitSafely(
    String workspacePath, {
    required String commitSha,
  }) async {
    final normalizedSha = commitSha.trim();
    if (normalizedSha.isEmpty) {
      return const GitOperationResult(success: false, message: 'Commit na obnovu nebol zadaný.');
    }
    if (!await Directory(workspacePath).exists()) {
      return const GitOperationResult(success: false, message: 'Vybraný pracovný priečinok neexistuje.');
    }

    try {
      final status = await Process.run(
        'git',
        const ['status', '--porcelain'],
        workingDirectory: workspacePath,
        runInShell: true,
      );
      if (status.exitCode != 0) {
        return GitOperationResult(
          success: false,
          message: 'Git stav sa nepodarilo načítať: ${status.stderr.toString().trim()}',
        );
      }
      if (status.stdout.toString().trim().isNotEmpty) {
        return const GitOperationResult(
          success: false,
          message: 'Obnova bola zrušená, pretože projekt obsahuje necommitnuté zmeny.',
        );
      }

      final verify = await Process.run(
        'git',
        <String>['rev-parse', '--verify', '$normalizedSha^{commit}'],
        workingDirectory: workspacePath,
        runInShell: true,
      );
      if (verify.exitCode != 0) {
        return const GitOperationResult(success: false, message: 'Vybraný commit už v repozitári neexistuje.');
      }

      final current = await Process.run(
        'git',
        const ['rev-parse', '--short', 'HEAD'],
        workingDirectory: workspacePath,
        runInShell: true,
      );
      final currentShort = current.stdout.toString().trim();
      final now = DateTime.now();
      String two(int value) => value.toString().padLeft(2, '0');
      final stamp = '${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}${two(now.second)}';
      final backupBranch = 'backup/pre-restore-$stamp';
      final targetShort = normalizedSha.length > 8 ? normalizedSha.substring(0, 8) : normalizedSha;
      final restoreBranch = 'restore/$targetShort-$stamp';

      final backup = await Process.run(
        'git',
        <String>['branch', backupBranch, 'HEAD'],
        workingDirectory: workspacePath,
        runInShell: true,
      );
      if (backup.exitCode != 0) {
        return GitOperationResult(
          success: false,
          message: 'Bezpečnostnú vetvu sa nepodarilo vytvoriť: ${backup.stderr.toString().trim()}',
        );
      }

      var checkout = await Process.run(
        'git',
        <String>['switch', '-c', restoreBranch, normalizedSha],
        workingDirectory: workspacePath,
        runInShell: true,
      );
      if (checkout.exitCode != 0) {
        checkout = await Process.run(
          'git',
          <String>['checkout', '-b', restoreBranch, normalizedSha],
          workingDirectory: workspacePath,
          runInShell: true,
        );
      }
      if (checkout.exitCode != 0) {
        await Process.run(
          'git',
          <String>['branch', '-D', backupBranch],
          workingDirectory: workspacePath,
          runInShell: true,
        );
        final details = checkout.stderr.toString().trim().isNotEmpty
            ? checkout.stderr.toString().trim()
            : checkout.stdout.toString().trim();
        return GitOperationResult(success: false, message: 'Obnova buildu zlyhala: $details');
      }

      return GitOperationResult(
        success: true,
        message: 'Build $targetShort bol obnovený vo vetve $restoreBranch. Pôvodný stav ${currentShort.isEmpty ? '' : '($currentShort) '}je uložený vo vetve $backupBranch.',
      );
    } on ProcessException catch (e) {
      return GitOperationResult(success: false, message: 'Git sa nepodarilo spustiť: ${e.message}');
    } catch (e) {
      return GitOperationResult(success: false, message: 'Obnova buildu zlyhala: $e');
    }
  }

  Future<GitWorkspaceStatus> inspect(String workspacePath) async {
    if (!await Directory(workspacePath).exists()) {
      return GitWorkspaceStatus(path: workspacePath, gitAvailable: true, isRepository: false, branch: null, changedFiles: const [], error: 'Vybraný priečinok neexistuje.');
    }
    try {
      final version = await Process.run('git', const ['--version'], runInShell: true);
      if (version.exitCode != 0) {
        return GitWorkspaceStatus(path: workspacePath, gitAvailable: false, isRepository: false, branch: null, changedFiles: const [], error: 'Git nie je dostupný v PATH.');
      }
      final repo = await Process.run('git', const ['rev-parse', '--is-inside-work-tree'], workingDirectory: workspacePath, runInShell: true);
      if (repo.exitCode != 0 || repo.stdout.toString().trim() != 'true') {
        return GitWorkspaceStatus(path: workspacePath, gitAvailable: true, isRepository: false, branch: null, changedFiles: const []);
      }
      final branch = await Process.run('git', const ['branch', '--show-current'], workingDirectory: workspacePath, runInShell: true);
      final status = await Process.run('git', const ['status', '--porcelain'], workingDirectory: workspacePath, runInShell: true);
      final files = status.stdout.toString().split(RegExp(r'\r?\n')).where((e) => e.trim().isNotEmpty).toList(growable: false);
      final branchName = branch.stdout.toString().trim();
      return GitWorkspaceStatus(path: workspacePath, gitAvailable: true, isRepository: true, branch: branchName.isEmpty ? '(detached HEAD)' : branchName, changedFiles: files, error: status.exitCode == 0 ? null : status.stderr.toString().trim());
    } on ProcessException catch (e) {
      return GitWorkspaceStatus(path: workspacePath, gitAvailable: false, isRepository: false, branch: null, changedFiles: const [], error: 'Git sa nepodarilo spustiť: ${e.message}');
    } catch (e) {
      return GitWorkspaceStatus(path: workspacePath, gitAvailable: true, isRepository: false, branch: null, changedFiles: const [], error: 'Kontrola Git workspace zlyhala: $e');
    }
  }
}
