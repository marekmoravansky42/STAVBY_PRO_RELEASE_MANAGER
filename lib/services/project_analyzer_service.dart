import 'dart:io';

import 'package:path/path.dart' as path;

class ProjectTodoItem {
  const ProjectTodoItem({
    required this.kind,
    required this.relativeFile,
    required this.line,
    required this.message,
    required this.module,
  });

  final String kind;
  final String relativeFile;
  final int line;
  final String message;
  final String? module;
}

class ProjectModuleAnalysis {
  const ProjectModuleAnalysis({
    required this.name,
    required this.dartFiles,
    required this.screens,
    required this.services,
    required this.databaseTables,
    required this.routes,
    required this.relativeFiles,
    required this.todos,
    required this.imports,
  });

  final String name;
  final int dartFiles;
  final List<String> screens;
  final List<String> services;
  final List<String> databaseTables;
  final List<String> routes;
  final List<String> relativeFiles;
  final List<ProjectTodoItem> todos;
  final List<String> imports;

  int get healthWarnings => todos.length;
  String get healthLabel => healthWarnings == 0 ? 'OK' : '$healthWarnings TODO';
}

class ProjectAnalysisResult {
  const ProjectAnalysisResult({
    required this.projectPath,
    required this.dartFiles,
    required this.modules,
    required this.screens,
    required this.services,
    required this.databaseTables,
    required this.routes,
    required this.todos,
    required this.generatedAt,
  });

  final String projectPath;
  final int dartFiles;
  final List<ProjectModuleAnalysis> modules;
  final List<String> screens;
  final List<String> services;
  final List<String> databaseTables;
  final List<String> routes;
  final List<ProjectTodoItem> todos;
  final DateTime generatedAt;
}

class _MutableModuleAnalysis {
  _MutableModuleAnalysis(this.name);

  final String name;
  final List<String> files = <String>[];
  final Set<String> screens = <String>{};
  final Set<String> services = <String>{};
  final Set<String> databaseTables = <String>{};
  final Set<String> routes = <String>{};
  final Set<String> imports = <String>{};
  final List<ProjectTodoItem> todos = <ProjectTodoItem>[];
}

class ProjectAnalyzerService {
  const ProjectAnalyzerService();

  Future<ProjectAnalysisResult> analyze(String projectPath) async {
    final libDirectory = Directory(path.join(projectPath, 'lib'));
    if (!await libDirectory.exists()) {
      throw const FileSystemException('Projekt neobsahuje priečinok lib/.');
    }

    final dartFiles = <File>[];
    await for (final entity in libDirectory.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.dart')) {
        dartFiles.add(entity);
      }
    }

    final moduleMap = <String, _MutableModuleAnalysis>{};
    final screens = <String>{};
    final services = <String>{};
    final tables = <String>{};
    final routes = <String>{};
    final todos = <ProjectTodoItem>[];

    final classPattern = RegExp(r'class\s+([A-Za-z_][A-Za-z0-9_]*)');
    final tablePatterns = <RegExp>[
      RegExp(r'''CREATE\s+TABLE(?:\s+IF\s+NOT\s+EXISTS)?\s+[`"']?([A-Za-z_][A-Za-z0-9_]*)''', caseSensitive: false),
      RegExp(r'''from\s*:\s*[`"']([A-Za-z_][A-Za-z0-9_]*)[`"']''', caseSensitive: false),
      RegExp(r'''table\s*\(\s*[`"']([A-Za-z_][A-Za-z0-9_]*)[`"']''', caseSensitive: false),
    ];
    final routePattern = RegExp(r'''(?:routeName|path|name)\s*[:=]\s*[`"']([^`"']+)[`"']''');
    final importPattern = RegExp(r'''import\s+[`"']([^`"']+)[`"']''');
    final todoPattern = RegExp(r'\b(TODO|FIXME|HACK)\b\s*:?[ \t]*(.*)', caseSensitive: false);

    for (final file in dartFiles) {
      final relative = path.relative(file.path, from: libDirectory.path).replaceAll('\\', '/');
      final segments = relative.split('/');
      _MutableModuleAnalysis? module;
      String? moduleName;
      if (segments.length > 2 && segments.first == 'features') {
        moduleName = segments[1];
        module = moduleMap.putIfAbsent(moduleName, () => _MutableModuleAnalysis(moduleName!));
        module.files.add(relative);
      }

      String content;
      try {
        content = await file.readAsString();
      } catch (_) {
        continue;
      }

      for (final match in classPattern.allMatches(content)) {
        final className = match.group(1)!;
        if (className.endsWith('Page') ||
            className.endsWith('Screen') ||
            className.endsWith('View') ||
            className.endsWith('Dialog')) {
          screens.add(className);
          module?.screens.add(className);
        }
        if (className.endsWith('Service') ||
            className.endsWith('Repository') ||
            className.endsWith('Controller')) {
          services.add(className);
          module?.services.add(className);
        }
      }

      for (final pattern in tablePatterns) {
        for (final match in pattern.allMatches(content)) {
          final value = match.group(1);
          if (value != null && value.isNotEmpty) {
            tables.add(value);
            module?.databaseTables.add(value);
          }
        }
      }
      for (final match in routePattern.allMatches(content)) {
        final value = match.group(1);
        if (value != null && value.trim().isNotEmpty) {
          final route = value.trim();
          routes.add(route);
          module?.routes.add(route);
        }
      }
      for (final match in importPattern.allMatches(content)) {
        final value = match.group(1);
        if (value != null && value.trim().isNotEmpty) {
          module?.imports.add(value.trim());
        }
      }

      final lines = content.split('\n');
      for (var index = 0; index < lines.length; index++) {
        final match = todoPattern.firstMatch(lines[index]);
        if (match == null) continue;
        final item = ProjectTodoItem(
          kind: match.group(1)!.toUpperCase(),
          relativeFile: relative,
          line: index + 1,
          message: (match.group(2) ?? '').trim(),
          module: moduleName,
        );
        todos.add(item);
        module?.todos.add(item);
      }
    }

    List<String> sorted(Set<String> source) => source.toList()..sort();
    final modules = moduleMap.values.map((module) {
      module.files.sort();
      module.todos.sort((a, b) {
        final byFile = a.relativeFile.compareTo(b.relativeFile);
        return byFile != 0 ? byFile : a.line.compareTo(b.line);
      });
      return ProjectModuleAnalysis(
        name: module.name,
        dartFiles: module.files.length,
        screens: sorted(module.screens),
        services: sorted(module.services),
        databaseTables: sorted(module.databaseTables),
        routes: sorted(module.routes),
        relativeFiles: List<String>.unmodifiable(module.files),
        todos: List<ProjectTodoItem>.unmodifiable(module.todos),
        imports: sorted(module.imports),
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    todos.sort((a, b) {
      final byFile = a.relativeFile.compareTo(b.relativeFile);
      return byFile != 0 ? byFile : a.line.compareTo(b.line);
    });

    return ProjectAnalysisResult(
      projectPath: projectPath,
      dartFiles: dartFiles.length,
      modules: modules,
      screens: sorted(screens),
      services: sorted(services),
      databaseTables: sorted(tables),
      routes: sorted(routes),
      todos: List<ProjectTodoItem>.unmodifiable(todos),
      generatedAt: DateTime.now(),
    );
  }
}
