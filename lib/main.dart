import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import 'app/app_startup.dart';
import 'app/app_theme.dart';
import 'app/application_controller.dart';
import 'app/app_version.dart';
import 'core/performance/startup_performance.dart';
import 'core/projects/project_profile.dart';
import 'core/services/project_service.dart';
import 'core/services/workspace_manager_service.dart';
import 'core/services/project_snapshot_service.dart';
import 'core/plugin_marketplace/plugin_marketplace_cache.dart';
import 'core/plugin_marketplace/plugin_marketplace_client.dart';
import 'core/plugin_marketplace/plugin_marketplace_repository.dart';
import 'design_system.dart';
import 'features/android_workspace/android_workspace_controller.dart';
import 'features/diagnostics/diagnostics_controller.dart';
import 'features/git_workspace/git_workspace_controller.dart';
import 'features/plugin_marketplace/plugin_marketplace_controller.dart';
import 'features/plugin_marketplace/plugin_marketplace_page.dart';
import 'features/release_wizard/release_wizard_controller.dart';
import 'features/release_pipeline_designer/release_pipeline_designer.dart';
import 'features/remote_agents/remote_agents_page.dart';
import 'features/windows_workspace/windows_workspace_controller.dart';
import 'models/project_info.dart';
import 'services/pubspec_service.dart';
import 'services/github_settings_service.dart';
import 'services/app_settings_service.dart';
import 'services/git_service.dart';
import 'services/build_history_service.dart';
import 'services/project_analyzer_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() {
  AppStartup.run(const ReleaseManagerApp());
}

class ReleaseManagerApp extends StatefulWidget {
  const ReleaseManagerApp({
    super.key,
    this.loadSavedTheme = true,
    this.home,
  });

  final bool loadSavedTheme;
  final Widget? home;

  @override
  State<ReleaseManagerApp> createState() => _ReleaseManagerAppState();
}

class _ReleaseManagerAppState extends State<ReleaseManagerApp> {
  final AppSettingsService _settingsService = const AppSettingsService();

  @override
  void initState() {
    super.initState();
    if (widget.loadSavedTheme) {
      _loadThemeMode();
    }
  }

  Future<void> _loadThemeMode() async {
    final settings = await _settingsService.load();
    appThemeMode.value = settings.darkMode ? ThemeMode.dark : ThemeMode.light;
    StartupPerformance.mark('téma a nastavenia');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, themeMode, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'STAVBY PRO Release Manager',
        navigatorKey: appNavigatorKey,
        themeMode: themeMode,
        theme: AppTheme.build(Brightness.light),
        darkTheme: AppTheme.build(Brightness.dark),
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: const TextScaler.linear(0.90),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: widget.home ?? const ReleaseManagerPage(),
      ),
    );
  }
}

class _GitWorkflowStep extends StatelessWidget {
  const _GitWorkflowStep({required this.number, required this.icon, required this.label});

  final String number;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CircleAvatar(
          radius: 13,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 7),
        Icon(icon, size: 18),
        const SizedBox(width: 5),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
      ],
    );
  }
}

class _ColorIcon extends StatelessWidget {
  const _ColorIcon({
    required this.icon,
    required this.color,
    this.selected = false,
  });

  final IconData icon;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: selected ? 42 : 38,
      height: selected ? 42 : 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: selected ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: selected ? 0.60 : 0.28),
        ),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class ReleaseManagerPage extends StatefulWidget {
  const ReleaseManagerPage({super.key});

  @override
  State<ReleaseManagerPage> createState() => _ReleaseManagerPageState();
}

enum _CheckStatus { checking, ok, warning, error }



class _PreflightDialog extends StatefulWidget {
  const _PreflightDialog({required this.checks, required this.allOk});

  final List<_PreflightCheck> checks;
  final bool allOk;

  @override
  State<_PreflightDialog> createState() => _PreflightDialogState();
}

class _PreflightDialogState extends State<_PreflightDialog> {
  static const int _initialSeconds = 3;
  Timer? _timer;
  int _secondsLeft = _initialSeconds;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    if (widget.allOk) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _closed) {
          timer.cancel();
          return;
        }
        if (_secondsLeft <= 1) {
          _finish(true);
        } else {
          setState(() => _secondsLeft--);
        }
      });
    }
  }

  void _finish(bool result) {
    if (_closed || !mounted) return;
    _closed = true;
    _timer?.cancel();
    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.allOk
          ? 'Predletová kontrola úspešná'
          : 'Release nemožno vytvoriť'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 520,
          maxWidth: 620,
          maxHeight: 470,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.checks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final check = widget.checks[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Icon(
                        check.ok ? Icons.check_circle : Icons.cancel,
                        color: check.ok ? Colors.green : Colors.red,
                      ),
                      title: Text(check.label),
                      subtitle: Text(check.detail),
                    );
                  },
                ),
              ),
            ),
            if (widget.allOk) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                key: const Key('preflightCountdown'),
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Automatické pokračovanie o $_secondsLeft s...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => _finish(false),
          child: Text(widget.allOk ? 'ZRUŠIŤ' : 'ZAVRIEŤ'),
        ),
        if (widget.allOk)
          FilledButton(
            key: const Key('preflightContinueButton'),
            onPressed: () => _finish(true),
            child: const Text('POKRAČOVAŤ TERAZ'),
          ),
      ],
    );
  }
}

class _PreflightCheck {
  const _PreflightCheck(this.label, this.ok, this.detail);

  final String label;
  final bool ok;
  final String detail;
}

class _ProjectCheck {
  const _ProjectCheck(this.label, this.status, this.detail);

  final String label;
  final _CheckStatus status;
  final String detail;
}

class _ReleaseManagerPageState extends State<ReleaseManagerPage> {
  final ApplicationController _application = ApplicationController();
  late final PluginMarketplaceController _pluginMarketplaceController;
  final ReleasePipelineDesignerController _pipelineDesignerController =
      ReleasePipelineDesignerController();
  late final ReleasePipelineExecutionController _pipelineExecutionController =
      ReleasePipelineExecutionController(onLog: _addLog);

  Future<void> _writeCrashLog(
    Object error,
    StackTrace stackTrace, {
    String step = 'Neobslúžená chyba aplikácie',
    String? projectPath,
  }) {
    return AppStartup.writeCrashLog(
      error,
      stackTrace,
      step: step,
      projectPath: projectPath,
    );
  }

  final GitService _gitService = const GitService();
  final PubspecService _pubspecService = const PubspecService();
  final GitHubSettingsService _githubSettingsService = const GitHubSettingsService();
  final AppSettingsService _appSettingsService = const AppSettingsService();
  final BuildHistoryService _buildHistoryService = const BuildHistoryService();
  final ProjectAnalyzerService _projectAnalyzerService = const ProjectAnalyzerService();
  final ProjectService _projectService = const ProjectService();
  final WorkspaceManagerService _workspaceManager = const WorkspaceManagerService();
  final ProjectSnapshotService _snapshotService = const ProjectSnapshotService();
  final TextEditingController _githubOwnerController = TextEditingController();
  final TextEditingController _githubRepositoryController = TextEditingController();
  final TextEditingController _githubTokenController = TextEditingController();
  final TextEditingController _apkUrlController = TextEditingController();
  final TextEditingController _newsController = TextEditingController();
  final TextEditingController _fixesController = TextEditingController();
  final TextEditingController _managerVersionController = TextEditingController(text: ReleaseManagerVersion.version);
  final TextEditingController _managerBuildController = TextEditingController(text: ReleaseManagerVersion.build.toString());
  final TextEditingController _managerReleaseNotesController = TextEditingController();
  DiagnosticsController get _diagnostics => _application.diagnostics;
  List<String> get _logs => _diagnostics.logs;
  final ScrollController _terminalScrollController = ScrollController();
  final List<Map<String, dynamic>> _releaseHistory = <Map<String, dynamic>>[];
  List<BuildHistoryEntry> _buildHistory = const <BuildHistoryEntry>[];
  bool _buildHistoryLoading = false;
  final List<_ProjectCheck> _projectChecks = <_ProjectCheck>[];
  final List<String> _recentProjectPaths = <String>[];
  final List<ProjectProfile> _projectProfiles = <ProjectProfile>[];
  String? _activeProjectProfileId;
  bool _projectProfilesLoading = true;
  List<WorkspaceHealthItem> _workspaceHealth = const <WorkspaceHealthItem>[];
  bool _workspaceHealthLoading = false;
  bool _startupWizardShown = false;
  ProjectSnapshotInfo? _lastProjectSnapshot;
  bool _snapshotRunning = false;
  final List<String> _recentGitWorkspacePaths = <String>[];
  int _selectedPage = 0;
  bool _developerMode = false;
  bool _sidebarCollapsed = false;
  ProjectAnalysisResult? _projectAnalysis;
  final TextEditingController _projectAnalyzerSearchController = TextEditingController();
  final TextEditingController _gitHistorySearchController = TextEditingController();
  String _gitHistorySort = 'date';
  String _projectAnalyzerSearchQuery = '';
  String _projectAnalyzerFilter = 'all';
  bool _projectAnalyzerExpandAll = false;
  int _projectAnalyzerExpansionGeneration = 0;
  bool _projectAnalysisRunning = false;
  String? _projectAnalysisError;
  GitWorkspaceController get _gitWorkspace => _application.gitWorkspace;

  String? get _gitWorkspacePath => _gitWorkspace.workspacePath;
  set _gitWorkspacePath(String? value) => _gitWorkspace.workspacePath = value;
  GitWorkspaceStatus? get _gitWorkspaceStatus => _gitWorkspace.workspaceStatus;
  set _gitWorkspaceStatus(GitWorkspaceStatus? value) => _gitWorkspace.workspaceStatus = value;
  bool get _gitWorkspaceLoading => _gitWorkspace.workspaceLoading;
  set _gitWorkspaceLoading(bool value) => _gitWorkspace.workspaceLoading = value;
  bool get _gitRepositoryInitializing => _gitWorkspace.repositoryInitializing;
  set _gitRepositoryInitializing(bool value) => _gitWorkspace.repositoryInitializing = value;
  bool get _gitCommitRunning => _gitWorkspace.commitRunning;
  set _gitCommitRunning(bool value) => _gitWorkspace.commitRunning = value;
  bool get _gitTagRunning => _gitWorkspace.tagRunning;
  set _gitTagRunning(bool value) => _gitWorkspace.tagRunning = value;
  bool _gitBuildPublishRunning = false;
  bool _workspaceSyncRunning = false;
  ({String version, int build, String stage})? _projectIdentitySnapshot;
  bool _projectIdentityLoading = false;
  bool _oneClickBuildRunning = false;
  int _oneClickBuildCompletedSteps = 0;
  String _oneClickBuildCurrentStep = 'Čaká';
  int _oneClickBuildResumeIndex = 0;
  String? _oneClickBuildFailedLabel;
  List<String> _oneClickBuildFailedArguments = const <String>[];
  List<String> _oneClickBuildFailedOutput = const <String>[];
  int? _oneClickBuildFailedExitCode;
  Object? _oneClickBuildFailedError;
  StackTrace? _oneClickBuildFailedStackTrace;
  bool get _gitRestoreRunning => _gitWorkspace.restoreRunning;
  set _gitRestoreRunning(bool value) => _gitWorkspace.restoreRunning = value;
  bool get _gitDiffRunning => _gitWorkspace.diffRunning;
  set _gitDiffRunning(bool value) => _gitWorkspace.diffRunning = value;
  List<GitCommitEntry> get _gitHistory => _gitWorkspace.history;
  set _gitHistory(List<GitCommitEntry> value) => _gitWorkspace.history = value;
  ProjectInfo? _project;
  bool _busy = false;
  String? _activeCommand;
  AndroidWorkspaceController get _androidWorkspace =>
      _application.androidWorkspace;

  String? get _apkPath => _androidWorkspace.apkPath;
  set _apkPath(String? value) => _androidWorkspace.apkPath = value;
  int? get _apkSizeBytes => _androidWorkspace.apkSizeBytes;
  set _apkSizeBytes(int? value) => _androidWorkspace.apkSizeBytes = value;
  String? get _apkSha256 => _androidWorkspace.apkSha256;
  set _apkSha256(String? value) => _androidWorkspace.apkSha256 = value;
  String? get _aabPath => _androidWorkspace.aabPath;
  set _aabPath(String? value) => _androidWorkspace.aabPath = value;
  int? get _aabSizeBytes => _androidWorkspace.aabSizeBytes;
  set _aabSizeBytes(int? value) => _androidWorkspace.aabSizeBytes = value;
  String? get _aabSha256 => _androidWorkspace.aabSha256;
  set _aabSha256(String? value) => _androidWorkspace.aabSha256 = value;
  String? _versionJsonPreview;
  String? _releaseNotesPreview;
  String? _githubReleasePreview;
  bool _githubSettingsLoading = true;
  bool _githubTesting = false;
  bool _githubUpdatingVersionJson = false;
  bool _githubCreatingRelease = false;
  bool _githubUploadingApk = false;
  bool _githubPublishing = false;
  String? _githubOperationTitle;
  String? _githubOperationDetail;
  double? _githubOperationProgress;
  int _githubOperationSentBytes = 0;
  int _githubOperationTotalBytes = 0;
  double? _githubOperationSpeedBytesPerSecond;
  Duration? _githubOperationEta;
  DateTime? _githubOperationStartedAt;
  DateTime? _githubLastProgressUpdate;
  bool _githubTokenVisible = false;
  bool _githubConnected = false;
  String _githubStatus = 'Nastavenie ešte nebolo otestované';
  bool _managerUpdateChecking = false;
  String _managerUpdateStatus = 'Kontrola aktualizácie ešte neprebehla';
  String? _latestManagerVersion;
  int? _latestManagerBuild;
  String? _latestManagerReleaseUrl;
  String? _latestManagerDownloadUrl;
  String? _latestManagerAssetName;
  bool _managerUpdateDownloading = false;
  bool _appSettingsLoading = true;
  String? _managerUpdateDownloadDirectory;
  String? _managerProjectPath;
  String? _managerReleaseDirectoryPath;
  String? _managerPackagePath;
  bool _managerBuildRunning = false;
  bool _managerBuildSucceeded = false;
  bool _managerPublished = false;
  bool _managerApplicationLaunched = false;
  bool _managerPublishing = false;
  bool _zipExtracting = false;
  bool get _androidZipExtracted => _androidWorkspace.zipExtracted;
  set _androidZipExtracted(bool value) => _androidWorkspace.zipExtracted = value;
  String? get _androidExtractedProjectPath =>
      _androidWorkspace.extractedProjectPath;
  set _androidExtractedProjectPath(String? value) =>
      _androidWorkspace.extractedProjectPath = value;
  bool _windowsZipExtracted = false;
  String? _windowsExtractedProjectPath;
  String? _windowsReleaseExportDirectory;
  String? _windowsBuiltExePath;
  String? _windowsExportedPath;
  String _windowsLaunchStatus = 'EXE ešte nebolo spustené.';
  WindowsWorkspaceController get _windowsWorkspace =>
      _application.windowsWorkspace;
  String? get _androidReleaseExportDirectory =>
      _androidWorkspace.releaseExportDirectory;
  set _androidReleaseExportDirectory(String? value) =>
      _androidWorkspace.releaseExportDirectory = value;
  String? get _androidExportedApkPath => _androidWorkspace.exportedApkPath;
  set _androidExportedApkPath(String? value) =>
      _androidWorkspace.exportedApkPath = value;
  Set<String> get _completedApkBuildSteps =>
      _androidWorkspace.completedBuildSteps;
  ReleaseWizardController get _releaseWizard => _application.releaseWizard;
  bool get _releaseWizardRunning => _releaseWizard.running;
  set _releaseWizardRunning(bool value) => _releaseWizard.running = value;
  int get _releaseWizardStep => _releaseWizard.step;
  set _releaseWizardStep(int value) => _releaseWizard.step = value;
  String get _releaseWizardStatus => _releaseWizard.status;
  set _releaseWizardStatus(String value) => _releaseWizard.status = value;
  String? get _releaseWizardReportPath => _releaseWizard.reportPath;
  set _releaseWizardReportPath(String? value) => _releaseWizard.reportPath = value;
  String? get _releaseWizardReleaseDirectory => _releaseWizard.releaseDirectory;
  set _releaseWizardReleaseDirectory(String? value) =>
      _releaseWizard.releaseDirectory = value;
  List<String> get _releaseWizardCompletedSteps =>
      _releaseWizard.completedSteps;
  static const List<String> _releaseWizardPipelineSteps =
      ReleaseWizardController.pipelineSteps;
  double _flutterStepEstimatedProgress = 0;
  DateTime? _flutterStepStartedAt;
  Timer? _flutterStepProgressTimer;
  bool _strictAnalyzeMode = false;
  int _lastAnalyzeErrors = 0;
  int _lastAnalyzeWarnings = 0;
  int _lastAnalyzeInfos = 0;
  String _lastAnalyzeStatus = 'Analýza ešte neprebehla.';

  ({int errors, int warnings, int infos}) _parseAnalyzeIssues(List<String> output) {
    var errors = 0;
    var warnings = 0;
    var infos = 0;
    for (final rawLine in output) {
      final line = rawLine.replaceFirst(RegExp(r'^CHYBA:\s*'), '').trimLeft();
      if (RegExp(r'^error\s+-', caseSensitive: false).hasMatch(line)) {
        errors++;
      } else if (RegExp(r'^warning\s+-', caseSensitive: false).hasMatch(line)) {
        warnings++;
      } else if (RegExp(r'^info\s+-', caseSensitive: false).hasMatch(line)) {
        infos++;
      }
    }
    return (errors: errors, warnings: warnings, infos: infos);
  }

  bool _acceptAnalyzeResult({required int exitCode, required List<String> output}) {
    final issues = _parseAnalyzeIssues(output);
    if (mounted) {
      setState(() {
        _lastAnalyzeErrors = issues.errors;
        _lastAnalyzeWarnings = issues.warnings;
        _lastAnalyzeInfos = issues.infos;
        _lastAnalyzeStatus = issues.errors > 0
            ? 'Zlyhanie: ${issues.errors} chýb'
            : issues.warnings + issues.infos > 0
                ? 'Dokončené s ${issues.warnings + issues.infos} upozorneniami'
                : 'Bez problémov';
      });
    }
    if (exitCode == 0) return true;
    return !_strictAnalyzeMode && issues.errors == 0 &&
        (issues.warnings > 0 || issues.infos > 0);
  }

  String get _flutterStepElapsedText {
    final started = _flutterStepStartedAt;
    if (started == null) return '00:00';
    final elapsed = DateTime.now().difference(started);
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startFlutterStepProgress(String label) {
    _flutterStepProgressTimer?.cancel();
    _flutterStepStartedAt = DateTime.now();
    _flutterStepEstimatedProgress = 0.03;

    final expectedSeconds = switch (label) {
      'Flutter clean' || 'Windows Flutter clean' => 8.0,
      'Flutter pub get' || 'Windows Flutter pub get' => 18.0,
      'Flutter analyze' || 'Windows Flutter analyze' => 22.0,
      'Flutter test' || 'Windows Flutter test' => 25.0,
      'Release APK build' => 150.0,
      'Windows build' || 'Windows Release build' => 150.0,
      _ => 30.0,
    };

    _flutterStepProgressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _activeCommand != label || _flutterStepStartedAt == null) {
        return;
      }
      final seconds =
          DateTime.now().difference(_flutterStepStartedAt!).inSeconds.toDouble();
      // Flutter neposkytuje spoľahlivé presné percentá pre tieto príkazy.
      // Zobrazujeme konzervatívny odhad, ktorý pred ukončením neprekročí 95 %.
      final ratio = seconds / expectedSeconds;
      final estimated = 0.03 + (0.92 * (ratio / (ratio + 0.75)));
      setState(() {
        _flutterStepEstimatedProgress = estimated.clamp(0.03, 0.95);
      });
    });
  }

  void _finishFlutterStepProgress({required bool success}) {
    _flutterStepProgressTimer?.cancel();
    _flutterStepProgressTimer = null;
    if (mounted) {
      setState(() {
        _flutterStepEstimatedProgress = success ? 1.0 : _flutterStepEstimatedProgress;
      });
    }
  }

  Future<void> _chooseGitWorkspace() async {
    final selected = await FilePicker.getDirectoryPath(
      dialogTitle: 'Vyber Git workspace',
      initialDirectory: _gitWorkspacePath ?? _project?.projectPath ?? _windowsExtractedProjectPath,
      lockParentWindow: true,
    );
    if (selected == null || selected.trim().isEmpty) return;
    setState(() => _gitWorkspacePath = selected);
    await _rememberGitWorkspace(selected);
    await _refreshGitWorkspace();
  }


  Future<void> _rememberGitWorkspace(String workspace) async {
    final normalized = workspace.trim();
    if (normalized.isEmpty) return;
    final updated = <String>[
      normalized,
      ..._recentGitWorkspacePaths.where((item) => item != normalized),
    ];
    if (updated.length > 8) updated.removeRange(8, updated.length);
    if (mounted) {
      setState(() {
        _recentGitWorkspacePaths
          ..clear()
          ..addAll(updated);
      });
    }
    await _appSettingsService.saveGitWorkspace(normalized, updated);
  }

  Future<void> _selectRecentGitWorkspace(String workspace) async {
    if (!await Directory(workspace).exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Git workspace už neexistuje: $workspace')),
      );
      final updated = _recentGitWorkspacePaths.where((item) => item != workspace).toList();
      setState(() => _recentGitWorkspacePaths
        ..clear()
        ..addAll(updated));
      await _appSettingsService.saveRecentGitWorkspacePaths(updated);
      return;
    }
    setState(() => _gitWorkspacePath = workspace);
    await _rememberGitWorkspace(workspace);
    await _refreshGitWorkspace();
  }

  Future<void> _initializeGitRepository() async {
    final workspace = _gitWorkspacePath ?? _project?.projectPath ?? _windowsExtractedProjectPath;
    if (workspace == null || workspace.trim().isEmpty) return;

    setState(() => _gitRepositoryInitializing = true);
    final result = await _gitService.initializeRepository(workspace);
    if (!mounted) return;

    setState(() => _gitRepositoryInitializing = false);
    _addLog(result.message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? const Color(0xFF2E7D32) : Theme.of(context).colorScheme.error,
      ),
    );
    await _refreshGitWorkspace();
  }

  // ignore: unused_element
  Future<void> _showGitCommitDialog() async {
    final status = _gitWorkspaceStatus;
    final workspace = _gitWorkspacePath;
    if (status == null || workspace == null || !status.isRepository || status.changedFiles.isEmpty) {
      return;
    }

    final titleController = TextEditingController(text: 'Build');
    final detailController = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: <Widget>[
            Icon(Icons.save_rounded, color: Color(0xFF2E7D32)),
            SizedBox(width: 10),
            Text('Commit zmien'),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('${status.changedFiles.length} zmenených súborov bude pridaných do commitu.'),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Názov commitu',
                  hintText: 'Build 268',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Popis zmien (voliteľný)',
                  hintText: 'Advanced Filters',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ZRUŠIŤ'),
          ),
          FilledButton.icon(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              final detail = detailController.text.trim();
              Navigator.of(dialogContext).pop(detail.isEmpty ? title : '$title\n\n$detail');
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text('VYTVORIŤ COMMIT'),
          ),
        ],
      ),
    );
    titleController.dispose();
    detailController.dispose();
    if (message == null || message.trim().isEmpty || !mounted) return;
    await _commitGitChanges(workspace, message);
  }

  Future<({String name, String email, bool global})?> _showGitIdentityDialog(GitIdentity current) async {
    final nameController = TextEditingController(text: current.name);
    final emailController = TextEditingController(text: current.email);
    var useGlobal = false;
    String? validationMessage;
    final result = await showDialog<({String name, String email, bool global})>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(children: <Widget>[Icon(Icons.person_rounded, color: Color(0xFF1976D2)), SizedBox(width: 10), Text('Git identita autora')]),
          content: SizedBox(
            width: 480,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
              const Text('Git potrebuje meno a e-mail, ktoré sa zapíšu ku každému commitu.'),
              const SizedBox(height: 16),
              TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Meno autora', prefixIcon: Icon(Icons.badge_rounded))),
              const SizedBox(height: 12),
              TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail autora', prefixIcon: Icon(Icons.email_rounded))),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: useGlobal,
                onChanged: (value) => setDialogState(() => useGlobal = value ?? false),
                title: const Text('Použiť pre všetky Git projekty v tomto počítači'),
                subtitle: Text(useGlobal ? 'Nastavenie bude globálne.' : 'Nastavenie zostane iba v tomto projekte.'),
              ),
              if (validationMessage != null) Text(validationMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ]),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('ZRUŠIŤ')),
            FilledButton.icon(
              onPressed: () {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                if (name.isEmpty || email.isEmpty || !email.contains('@')) {
                  setDialogState(() => validationMessage = 'Vyplň platné meno a e-mail autora.');
                  return;
                }
                Navigator.of(dialogContext).pop((name: name, email: email, global: useGlobal));
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('ULOŽIŤ A POKRAČOVAŤ'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    emailController.dispose();
    return result;
  }

  Future<void> _commitGitChanges(String workspace, String message) async {
    setState(() => _gitCommitRunning = true);
    try {
      final ignoreResult = await _gitService.ensureFlutterGitignore(workspace);
      _addLog(ignoreResult.message);
      final identity = await _gitService.readIdentity(workspace);
      if (!identity.isComplete) {
        if (!mounted) return;
        setState(() => _gitCommitRunning = false);
        final entered = await _showGitIdentityDialog(identity);
        if (entered == null || !mounted) return;
        setState(() => _gitCommitRunning = true);
        final identityResult = await _gitService.saveIdentity(workspace, name: entered.name, email: entered.email, global: entered.global);
        _addLog(identityResult.message);
        if (!identityResult.success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(identityResult.message), backgroundColor: Theme.of(context).colorScheme.error));
          return;
        }
      }
      final result = await _gitService.commitAll(workspace, message: message);
      if (!mounted) return;
      _addLog(result.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message), backgroundColor: result.success ? const Color(0xFF2E7D32) : Theme.of(context).colorScheme.error));
    } finally {
      if (mounted) setState(() => _gitCommitRunning = false);
      await _refreshGitWorkspace();
    }
  }


  Future<({String version, int build, String stage})?>
      _loadProjectIdentity(String workspace, {bool updateSnapshot = true}) async {
    final identity = await _readGitBuildIdentity(workspace);
    if (updateSnapshot && mounted) {
      setState(() {
        _projectIdentitySnapshot = identity;
        _projectIdentityLoading = false;
      });
    }
    return identity;
  }

  Future<void> _refreshProjectIdentitySnapshot([String? workspaceOverride]) async {
    final workspace = workspaceOverride ?? _gitWorkspacePath;
    if (workspace == null || workspace.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _projectIdentitySnapshot = null;
          _projectIdentityLoading = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _projectIdentityLoading = true);
    final identity = await _readGitBuildIdentity(workspace);
    if (!mounted) return;
    setState(() {
      _projectIdentitySnapshot = identity;
      _projectIdentityLoading = false;
    });
    if (identity != null) {
      _addLog(
        'ProjectVersionProvider: ${identity.version}+${identity.build} '
        '${identity.stage.toUpperCase()} ($workspace).',
      );
    } else {
      _addLog('ProjectVersionProvider: identitu projektu sa nepodarilo načítať ($workspace).');
    }
  }

  Future<String> _suggestGitTagName(String workspace) async {
    try {
      final pubspec = File('$workspace${Platform.pathSeparator}pubspec.yaml');
      if (await pubspec.exists()) {
        final text = await pubspec.readAsString();
        final match = RegExp(r'^version:\s*([^+\s]+)\+(\d+)\s*$', multiLine: true).firstMatch(text);
        if (match != null) return '${match.group(1)}_B${match.group(2)}';
      }
    } catch (_) {}
    final now = DateTime.now();
    return 'build_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  // ignore: unused_element
  Future<void> _showCreateGitTagDialog() async {
    final workspace = _gitWorkspacePath;
    final status = _gitWorkspaceStatus;
    if (workspace == null || status?.isRepository != true || status!.changedFiles.isNotEmpty) return;
    final suggested = await _suggestGitTagName(workspace);
    if (!mounted) return;
    final tagController = TextEditingController(text: suggested);
    final messageController = TextEditingController(text: 'STAVBY PRO $suggested');
    final data = await showDialog<({String tag, String message})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(children: <Widget>[Icon(Icons.sell_rounded, color: Color(0xFFF9A825)), SizedBox(width: 10), Text('Vytvoriť tag buildu')]),
        content: SizedBox(width: 500, child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          TextField(controller: tagController, autofocus: true, decoration: const InputDecoration(labelText: 'Názov tagu', hintText: '3.6.93_B267', prefixIcon: Icon(Icons.sell_rounded))),
          const SizedBox(height: 12),
          TextField(controller: messageController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Poznámka k tagu', prefixIcon: Icon(Icons.notes_rounded))),
          const SizedBox(height: 10),
          const Text('Tag sa vytvorí na aktuálnom commite. Working tree musí byť čistý.'),
        ])),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('ZRUŠIŤ')),
          FilledButton.icon(onPressed: () {
            final tag = tagController.text.trim();
            if (tag.isEmpty) return;
            Navigator.of(dialogContext).pop((tag: tag, message: messageController.text.trim()));
          }, icon: const Icon(Icons.sell_rounded), label: const Text('VYTVORIŤ TAG')),
        ],
      ),
    );
    tagController.dispose();
    messageController.dispose();
    if (data == null || !mounted) return;
    setState(() => _gitTagRunning = true);
    try {
      final result = await _gitService.createTag(workspace, tagName: data.tag, message: data.message);
      if (!mounted) return;
      _addLog(result.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message), backgroundColor: result.success ? const Color(0xFF2E7D32) : Theme.of(context).colorScheme.error));
    } finally {
      if (mounted) setState(() => _gitTagRunning = false);
      await _refreshGitWorkspace();
    }
  }

  Future<({String version, int build, String stage})?> _readGitBuildIdentity(String workspace) async {
    try {
      final pubspec = File('$workspace${Platform.pathSeparator}pubspec.yaml');
      if (!await pubspec.exists()) return null;
      final text = await pubspec.readAsString();
      final match = RegExp(r'^version:\s*([^+\s]+)\+(\d+)\s*$', multiLine: true).firstMatch(text);
      if (match == null) return null;
      final version = match.group(1)!;
      final build = int.parse(match.group(2)!);
      var stage = 'dev';
      try {
        final candidates = <File>[
          File('$workspace${Platform.pathSeparator}lib${Platform.pathSeparator}features${Platform.pathSeparator}about${Platform.pathSeparator}version_service.dart'),
          File('$workspace${Platform.pathSeparator}lib${Platform.pathSeparator}app${Platform.pathSeparator}app_version.dart'),
        ];
        for (final versionFile in candidates) {
          if (!await versionFile.exists()) continue;
          final source = await versionFile.readAsString();
          final stageMatch = RegExp(r'''(?:stage|channel|suffix)\s*=\s*['"]([^'"]+)['"]''', caseSensitive: false).firstMatch(source);
          final detected = stageMatch?.group(1)?.trim().toLowerCase();
          if (detected != null && detected.isNotEmpty) {
            stage = detected;
            break;
          }
        }
      } catch (_) {}
      return (version: version, build: build, stage: stage);
    } catch (_) {
      return null;
    }
  }

  String _gitTagForBuild(({String version, int build, String stage}) identity) {
    final normalizedStage = identity.stage
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'v${identity.version}-${normalizedStage.isEmpty ? 'dev' : normalizedStage}-b${identity.build}';
  }

  Future<void> _showGitBuildPublisherDialog() async {
    final workspace = _gitWorkspacePath;
    final status = _gitWorkspaceStatus;
    if (workspace == null || status?.isRepository != true || _gitBuildPublishRunning) return;
    final identity = await _readGitBuildIdentity(workspace);
    if (!mounted) return;
    if (identity == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Z pubspec.yaml sa nepodarilo načítať verziu a build projektu.'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
      return;
    }
    final defaultTag = _gitTagForBuild(identity);
    final descriptionController = TextEditingController();
    final tagController = TextEditingController(text: defaultTag);
    final confirmed = await showDialog<({String message, String tag})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(children: <Widget>[
          Icon(Icons.cloud_upload_rounded, color: Color(0xFF2E7D32)),
          SizedBox(width: 10),
          Text('Uložiť build do Gitu'),
        ]),
        content: SizedBox(
          width: 620,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Projekt: $workspace', maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text('Vetva: ${status?.branch ?? '—'} • Zmenené súbory: ${status?.changedFiles.length ?? 0}'),
              const SizedBox(height: 6),
              Text('Verzia: ${identity.version} • Build: ${identity.build}'),
              const SizedBox(height: 14),
              TextField(
                controller: descriptionController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Popis zmien',
                  hintText: 'Napr. bezpečná správa archívu',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagController,
                decoration: const InputDecoration(
                  labelText: 'Git tag',
                  prefixIcon: Icon(Icons.sell_rounded),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Release Manager vykoná v správnom poradí: git add → commit → tag → push vetvy → push tagu. Existujúci tag nebude automaticky prepísaný.',
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('ZRUŠIŤ')),
          FilledButton.icon(
            onPressed: () {
              final description = descriptionController.text.trim();
              final tag = tagController.text.trim();
              if (description.isEmpty || tag.isEmpty) return;
              Navigator.of(dialogContext).pop((
                message: 'Build ${identity.build} - $description',
                tag: tag,
              ));
            },
            icon: const Icon(Icons.cloud_upload_rounded),
            label: const Text('ULOŽIŤ BUILD'),
          ),
        ],
      ),
    );
    descriptionController.dispose();
    tagController.dispose();
    if (confirmed == null || !mounted) return;

    setState(() => _gitBuildPublishRunning = true);
    try {
      _addLog('=== GIT BUILD PUBLISHER ===');
      _addLog('Workspace: $workspace');
      _addLog('Commit: ${confirmed.message}');
      _addLog('Tag: ${confirmed.tag}');
      final result = await _gitService.publishBuild(
        workspace,
        commitMessage: confirmed.message,
        tagName: confirmed.tag,
        requiredBranch: '',
      );
      if (!mounted) return;
      _addLog(result.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? const Color(0xFF2E7D32) : Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 6),
      ));
      if (result.success) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Row(children: <Widget>[
              Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
              SizedBox(width: 10),
              Text('Build bol uložený'),
            ]),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Commit, tag aj push na GitHub boli úspešne dokončené.'),
                  const SizedBox(height: 14),
                  Text('Vetva: ${result.branch ?? '—'}'),
                  Text('Commit: ${result.commitSha ?? '—'}'),
                  Text('Tag: ${result.tagName ?? '—'}'),
                  const SizedBox(height: 10),
                  const Text('Working tree sa po zatvorení automaticky obnoví.'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton.icon(
                onPressed: result.commitSha == null
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: result.commitSha!));
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Hash commitu bol skopírovaný.')));
                        }
                      },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('KOPÍROVAŤ HASH'),
              ),
              FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('HOTOVO')),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gitBuildPublishRunning = false);
      await _refreshGitWorkspace();
    }
  }


  Future<void> _showGitDiffDialog(GitCommitEntry entry) async {
    final workspace = _gitWorkspacePath;
    if (workspace == null || _gitDiffRunning) return;
    setState(() => _gitDiffRunning = true);
    final diff = await _gitService.diffWithParent(workspace, commitSha: entry.sha);
    if (!mounted) return;
    setState(() => _gitDiffRunning = false);
    if (diff == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Porovnanie commitu sa nepodarilo načítať.'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
      return;
    }

    String reportText() {
      final buffer = StringBuffer()
        ..writeln('STAVBY PRO Release Manager – Git Diff Report')
        ..writeln('Commit: ${entry.sha}')
        ..writeln('Správa: ${entry.subject}')
        ..writeln('Autor: ${entry.author}')
        ..writeln('Dátum: ${_formatGitDate(entry.date)}')
        ..writeln('Porovnanie: ${diff.parentSha == null ? 'prvý commit' : '${diff.parentSha!.substring(0, 8)} → ${entry.shortSha}'}')
        ..writeln('Zmenené súbory: ${diff.files.length}')
        ..writeln('Pridané riadky: ${diff.additions}')
        ..writeln('Odstránené riadky: ${diff.deletions}')
        ..writeln();
      for (final file in diff.files) {
        buffer.writeln('${file.isBinary ? 'BIN' : '+${file.additions} -${file.deletions}'}\t${file.path}');
      }
      return buffer.toString();
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(children: <Widget>[
          Icon(Icons.difference_rounded, color: Color(0xFF7B1FA2)),
          SizedBox(width: 10),
          Text('Porovnanie s predchádzajúcim commitom'),
        ]),
        content: SizedBox(
          width: 820,
          height: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(entry.subject.isEmpty ? '(bez správy)' : entry.subject,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              SelectableText('${entry.shortSha} • ${entry.author} • ${_formatGitDate(entry.date)}'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  Chip(avatar: const Icon(Icons.description_rounded, size: 18), label: Text('${diff.files.length} súborov')),
                  Chip(avatar: const Icon(Icons.add_rounded, size: 18), label: Text('+${diff.additions} riadkov')),
                  Chip(avatar: const Icon(Icons.remove_rounded, size: 18), label: Text('-${diff.deletions} riadkov')),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: diff.files.isEmpty
                    ? const Center(child: Text('Commit neobsahuje zmeny súborov.'))
                    : ListView.separated(
                        itemCount: diff.files.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final file = diff.files[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              file.isBinary ? Icons.image_rounded : Icons.description_rounded,
                              color: file.isBinary ? const Color(0xFFF57C00) : const Color(0xFF1976D2),
                            ),
                            title: SelectableText(file.path),
                            trailing: Text(file.isBinary ? 'BIN' : '+${file.additions}  -${file.deletions}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: reportText()));
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Diff report bol skopírovaný.')));
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('KOPÍROVAŤ REPORT'),
          ),
          TextButton.icon(
            onPressed: () async {
              final output = await FilePicker.saveFile(
                dialogTitle: 'Exportovať Git Diff Report',
                fileName: 'GIT_DIFF_${entry.shortSha}.txt',
                type: FileType.custom,
                allowedExtensions: const <String>['txt'],
              );
              if (output == null) return;
              final target = output.toLowerCase().endsWith('.txt') ? output : '$output.txt';
              await File(target).writeAsString(reportText(), flush: true);
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Report bol uložený: $target')));
              }
            },
            icon: const Icon(Icons.file_download_rounded),
            label: const Text('EXPORT REPORT'),
          ),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('ZAVRIEŤ')),
        ],
      ),
    );
  }

  Future<void> _showRestoreGitCommitDialog(GitCommitEntry entry) async {
    final workspace = _gitWorkspacePath;
    final status = _gitWorkspaceStatus;
    if (workspace == null || status == null || !status.isRepository || _gitRestoreRunning) return;

    if (status.changedFiles.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(children: <Widget>[
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF57C00)),
            SizedBox(width: 10),
            Text('Obnova nie je dostupná'),
          ]),
          content: const Text(
            'Projekt obsahuje necommitnuté zmeny. Najprv ich commitni alebo odstráň. '
            'Release Manager ich kvôli bezpečnosti nikdy automaticky neprepíše.',
          ),
          actions: <Widget>[
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('ROZUMIEM')),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(children: <Widget>[
          Icon(Icons.restore_rounded, color: Color(0xFF1565C0)),
          SizedBox(width: 10),
          Text('Obnoviť tento build'),
        ]),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(entry.subject.isEmpty ? '(commit bez správy)' : entry.subject,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SelectableText('${entry.shortSha} • ${entry.author} • ${_formatGitDate(entry.date)}'),
              if (entry.tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text('Tag: ${entry.tags.join(', ')}'),
              ],
              const SizedBox(height: 16),
              const Text(
                'Release Manager vytvorí bezpečnostnú vetvu z aktuálneho stavu a potom '
                'otvorí vybraný commit v novej obnovovacej vetve. Existujúca vetva dev ani história sa nevymažú.',
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('ZRUŠIŤ')),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.restore_rounded),
            label: const Text('OBNOVIŤ BUILD'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _gitRestoreRunning = true);
    final result = await _gitService.restoreCommitSafely(workspace, commitSha: entry.sha);
    if (!mounted) return;
    setState(() => _gitRestoreRunning = false);
    _addLog(result.message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.message),
      backgroundColor: result.success ? const Color(0xFF2E7D32) : Theme.of(context).colorScheme.error,
    ));
    await _refreshGitWorkspace();
  }

  String _formatGitDate(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshGitWorkspace() async {
    final workspace = _gitWorkspacePath ?? _project?.projectPath ?? _windowsExtractedProjectPath;
    if (workspace == null || workspace.trim().isEmpty) return;
    setState(() {
      _gitWorkspacePath = workspace;
      _gitWorkspaceLoading = true;
    });
    final status = await _gitService.inspect(workspace);
    final history = status.isRepository ? await _gitService.history(workspace) : const <GitCommitEntry>[];
    if (!mounted) return;
    setState(() {
      _gitWorkspaceStatus = status;
      _gitHistory = history;
      _gitWorkspaceLoading = false;
    });
    await _refreshProjectIdentitySnapshot(workspace);
    _addLog(status.isRepository
        ? 'Git workspace: ${status.branch}, ${status.changedFiles.length} zmien.'
        : 'Vybraný priečinok nie je Git repozitár.');
  }

  Widget _buildGitWorkspaceSection() {
    final status = _gitWorkspaceStatus;
    const accent = Color(0xFF2E7D32);
    final isRepository = status?.isRepository == true;
    final changedFiles = status?.changedFiles ?? const <String>[];
    final stagedCount = changedFiles.where((entry) {
      if (entry.length < 2) return false;
      final indexCode = entry[0];
      return indexCode != ' ' && indexCode != '?';
    }).length;
    final modifiedCount = changedFiles.length - stagedCount;
    final latestCommit = _gitHistory.isEmpty ? null : _gitHistory.first;
    final latestTag = _gitHistory
        .expand((entry) => entry.tags)
        .cast<String?>()
        .firstWhere((tag) => tag != null && tag.trim().isNotEmpty, orElse: () => null);
    final state = status == null
        ? 'Čaká na výber workspace'
        : !status.gitAvailable
            ? 'Git nie je dostupný'
            : isRepository
                ? (status.isClean ? 'Working tree je čistý' : 'Repozitár obsahuje zmeny')
                : 'Git repozitár nie je inicializovaný';

    Widget quickAction({
      required IconData icon,
      required String label,
      required VoidCallback? onPressed,
      bool primary = false,
    }) {
      final button = primary
          ? FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label))
          : OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label));
      return SizedBox(height: 38, child: button);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RMSectionCard(
          title: '🌿 Git Workspace 2.0',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: <Widget>[
                    const _ColorIcon(icon: Icons.account_tree_rounded, color: accent, selected: true),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(child: Text(state, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: (status?.isClean == true ? const Color(0xFF2E7D32) : const Color(0xFFF57C00)).withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status == null ? 'NEVYBRANÝ' : status.isClean ? 'CLEAN' : '${changedFiles.length} ZMIEN',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: status?.isClean == true ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_gitWorkspacePath ?? 'Vyber pracovný priečinok projektu.', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (_gitWorkspaceLoading) ...<Widget>[
                      const SizedBox(width: 14),
                      const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              RMAdaptiveGrid(
                spacing: 10,
                expandedColumns: 4,
                wideColumns: 4,
                children: <Widget>[
                  RMMetricCard(icon: Icons.account_tree_rounded, title: 'Vetva', value: status?.branch ?? '—', color: const Color(0xFF2E7D32)),
                  RMMetricCard(icon: Icons.commit_rounded, title: 'Posledný commit', value: latestCommit?.shortSha ?? '—', subtitle: latestCommit?.subject, color: const Color(0xFF7B1FA2)),
                  RMMetricCard(icon: Icons.sell_rounded, title: 'Posledný tag', value: latestTag ?? '—', color: const Color(0xFF1565C0)),
                  RMMetricCard(icon: Icons.edit_note_rounded, title: 'Working tree', value: status?.isClean == true ? 'Čistý' : '${changedFiles.length} zmien', subtitle: isRepository ? '$stagedCount staged • $modifiedCount ostatné' : 'Repozitár nie je pripravený', color: status?.isClean == true ? const Color(0xFF2E7D32) : const Color(0xFFF57C00)),
                ],
              ),
              if (status?.error != null && status!.error!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(status.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  quickAction(icon: Icons.folder_open_rounded, label: 'Vybrať workspace', onPressed: _gitWorkspaceLoading ? null : _chooseGitWorkspace, primary: true),
                  if (_recentGitWorkspacePaths.isNotEmpty)
                    PopupMenuButton<String>(
                      tooltip: 'Nedávne Git projekty',
                      onSelected: _selectRecentGitWorkspace,
                      itemBuilder: (context) => _recentGitWorkspacePaths
                          .map((workspace) => PopupMenuItem<String>(
                                value: workspace,
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.history_rounded),
                                  title: Text(path.basename(workspace), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(workspace, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ))
                          .toList(growable: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.history_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('NEDÁVNE PROJEKTY'),
                          ],
                        ),
                      ),
                    ),
                  if (status != null && status.gitAvailable && !isRepository)
                    quickAction(icon: Icons.add_circle_outline_rounded, label: 'Inicializovať Git', onPressed: _gitWorkspaceLoading || _gitRepositoryInitializing ? null : _initializeGitRepository, primary: true),
                  quickAction(icon: Icons.refresh_rounded, label: 'Obnoviť stav', onPressed: _gitWorkspaceLoading || _gitRepositoryInitializing || _gitCommitRunning || _gitWorkspacePath == null ? null : _refreshGitWorkspace),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        RMSectionCard(
          title: '🌿 Git Developer Center',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Ulož aktuálny build bezpečne v troch krokoch: commit, tag a push. Technické detaily zostávajú nižšie v histórii.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22)),
                ),
                child: const Row(
                  children: <Widget>[
                    Expanded(child: _GitWorkflowStep(number: '1', icon: Icons.commit_rounded, label: 'Commit')),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                    Expanded(child: _GitWorkflowStep(number: '2', icon: Icons.sell_rounded, label: 'Tag')),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                    Expanded(child: _GitWorkflowStep(number: '3', icon: Icons.cloud_upload_rounded, label: 'Push')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_gitWorkspacePath != null)
                FutureBuilder<({String version, int build, String stage})?>(
                  future: _readGitBuildIdentity(_gitWorkspacePath!),
                  builder: (context, snapshot) {
                    final identity = snapshot.data;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        spacing: 22,
                        runSpacing: 8,
                        children: <Widget>[
                          Text('Projekt: ${_gitWorkspacePath!}', overflow: TextOverflow.ellipsis),
                          Text('Vetva: ${status?.branch ?? '—'}'),
                          Text('Verzia: ${identity?.version ?? '—'}'),
                          Text('Build: ${identity?.build ?? '—'}'),
                          Text('Tag: ${identity == null ? '—' : _gitTagForBuild(identity)}'),
                          Text('Zmeny: ${changedFiles.length}'),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('gitBuildPublisherButton'),
                onPressed: !isRepository || changedFiles.isEmpty || _gitWorkspaceLoading || _gitCommitRunning || _gitTagRunning || _gitBuildPublishRunning
                    ? null
                    : _showGitBuildPublisherDialog,
                icon: _gitBuildPublishRunning
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_as_rounded),
                label: Text(_gitBuildPublishRunning ? 'UKLADÁM BUILD...' : 'ULOŽIŤ BUILD DO GITU'),
              ),
              const SizedBox(height: 8),
              Text(
                !isRepository
                    ? 'Najprv vyber platný Git workspace.'
                    : changedFiles.isEmpty
                        ? 'Working tree je čistý — nie sú žiadne zmeny na uloženie.'
                        : 'Pred uložením sa automaticky použije aktuálna Git vetva a overí sa origin, dostupnosť zmien a kolízia tagu.',
                style: TextStyle(
                  color: !isRepository
                      ? Theme.of(context).colorScheme.error
                      : changedFiles.isEmpty
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF1565C0),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final changedPanel = RMSectionCard(
              title: '📄 Zmeny pripravené na uloženie (${changedFiles.length})',
              child: status == null
                  ? const Text('Najprv vyber Git workspace.')
                  : !isRepository
                      ? const Text('Priečinok zatiaľ nie je Git repozitár.')
                      : changedFiles.isEmpty
                          ? const ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(Icons.check_circle_rounded, color: Color(0xFF43A047)), title: Text('Working tree je čistý.'))
                          : ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 330),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: changedFiles.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final entry = changedFiles[index];
                                  final code = entry.length >= 2 ? entry.substring(0, 2).trim() : '?';
                                  final file = entry.length > 3 ? entry.substring(3) : entry;
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(code.contains('?') ? Icons.add_circle_outline_rounded : Icons.description_rounded, color: code.contains('?') ? const Color(0xFFF57C00) : const Color(0xFF1976D2)),
                                    title: SelectableText(file, maxLines: 1),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
                                      child: Text(code.isEmpty ? 'M' : code, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                                    ),
                                  );
                                },
                              ),
                            ),
            );
            final query = _gitHistorySearchController.text.trim().toLowerCase();
            final visibleHistory = _gitHistory.where((entry) {
              if (query.isEmpty) return true;
              return entry.subject.toLowerCase().contains(query) ||
                  entry.author.toLowerCase().contains(query) ||
                  entry.sha.toLowerCase().contains(query) ||
                  entry.shortSha.toLowerCase().contains(query) ||
                  entry.tags.any((tag) => tag.toLowerCase().contains(query));
            }).toList();
            visibleHistory.sort((a, b) {
              switch (_gitHistorySort) {
                case 'build':
                  int buildOf(GitCommitEntry entry) {
                    final text = '${entry.subject} ${entry.tags.join(' ')}';
                    final match = RegExp(r'(?:build|b)(?:\s|-)*(\d+)', caseSensitive: false).firstMatch(text);
                    return int.tryParse(match?.group(1) ?? '') ?? -1;
                  }
                  return buildOf(b).compareTo(buildOf(a));
                case 'version':
                  return b.tags.join(' ').compareTo(a.tags.join(' '));
                default:
                  return (b.date ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.date ?? DateTime.fromMillisecondsSinceEpoch(0));
              }
            });
            final historyPanel = RMSectionCard(
              title: '📜 História uložených buildov',
              child: !isRepository
                  ? const Text('História bude dostupná po inicializácii repozitára a prvom commite.')
                  : _gitHistory.isEmpty
                      ? const ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(Icons.history_rounded), title: Text('Repozitár zatiaľ nemá žiadny commit.'))
                      : Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextField(
                                    controller: _gitHistorySearchController,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      prefixIcon: Icon(Icons.search_rounded),
                                      hintText: 'Hľadať build, verziu, autora alebo commit...',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                DropdownButton<String>(
                                  value: _gitHistorySort,
                                  onChanged: (value) => setState(() => _gitHistorySort = value ?? 'date'),
                                  items: const <DropdownMenuItem<String>>[
                                    DropdownMenuItem(value: 'date', child: Text('Dátum')),
                                    DropdownMenuItem(value: 'build', child: Text('Build')),
                                    DropdownMenuItem(value: 'version', child: Text('Verzia')),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (visibleHistory.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text('Žiadny commit nezodpovedá vyhľadávaniu.'),
                              )
                            else
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 330),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: visibleHistory.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final entry = visibleHistory[index];
                                    final published = entry.tags.isNotEmpty;
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          _ColorIcon(
                                            icon: published ? Icons.cloud_done_rounded : Icons.commit_rounded,
                                            color: published ? const Color(0xFF00897B) : const Color(0xFF7B1FA2),
                                            selected: true,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(entry.subject.isEmpty ? '(bez správy)' : entry.subject, style: const TextStyle(fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                const SizedBox(height: 4),
                                                Text('${entry.shortSha} • ${entry.author} • ${_formatGitDate(entry.date)}', style: Theme.of(context).textTheme.bodySmall),
                                                if (entry.tags.isNotEmpty) ...<Widget>[
                                                  const SizedBox(height: 5),
                                                  Wrap(spacing: 6, runSpacing: 4, children: entry.tags.map((tag) => Chip(label: Text(tag), visualDensity: VisualDensity.compact)).toList()),
                                                ],
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            tooltip: 'Akcie commitu',
                                            onSelected: (action) {
                                              switch (action) {
                                                case 'diff':
                                                  if (!_gitDiffRunning) _showGitDiffDialog(entry);
                                                  break;
                                                case 'restore':
                                                  if (!_gitRestoreRunning) _showRestoreGitCommitDialog(entry);
                                                  break;
                                                case 'copyHash':
                                                  Clipboard.setData(ClipboardData(text: entry.sha));
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hash commitu bol skopírovaný.')));
                                                  break;
                                                case 'copyMessage':
                                                  Clipboard.setData(ClipboardData(text: entry.subject));
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Správa commitu bola skopírovaná.')));
                                                  break;
                                              }
                                            },
                                            itemBuilder: (context) => const <PopupMenuEntry<String>>[
                                              PopupMenuItem(value: 'diff', child: ListTile(leading: Icon(Icons.difference_rounded), title: Text('Porovnať zmeny'))),
                                              PopupMenuItem(value: 'restore', child: ListTile(leading: Icon(Icons.restore_rounded), title: Text('Obnoviť build'))),
                                              PopupMenuDivider(),
                                              PopupMenuItem(value: 'copyHash', child: ListTile(leading: Icon(Icons.copy_rounded), title: Text('Kopírovať hash'))),
                                              PopupMenuItem(value: 'copyMessage', child: ListTile(leading: Icon(Icons.content_copy_rounded), title: Text('Kopírovať správu'))),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
            );
            if (!wide) return Column(children: <Widget>[changedPanel, const SizedBox(height: 14), historyPanel]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Expanded(flex: 4, child: changedPanel), const SizedBox(width: 14), Expanded(flex: 6, child: historyPanel)]);
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _pluginMarketplaceController = PluginMarketplaceController(
      repository: PluginMarketplaceRepository(
        client: PluginMarketplaceClient((_) async => _demoMarketplaceJson),
        cache: PluginMarketplaceCache(
          File(path.join(Directory.systemTemp.path, 'stavby_pro_release_manager', 'plugin_marketplace_demo.json')),
        ),
      ),
      indexUri: Uri.parse('demo://stavby-pro/plugin-marketplace.json'),
    );
    _addLog('Release Manager ${ReleaseManagerVersion.label} je pripravený.');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StartupPerformance.mark('prvý frame');
      _addLog(StartupPerformance.summary());
      unawaited(_checkPreviousCrashLog());
      unawaited(_loadGitHubSettings());
      unawaited(_loadAppSettings());
      unawaited(_loadBuildHistory());
    });
  }

  @override
  void dispose() {
    _flutterStepProgressTimer?.cancel();
    _pluginMarketplaceController.dispose();
    _pipelineExecutionController.dispose();
    _pipelineDesignerController.dispose();
    _application.dispose();
    _apkUrlController.dispose();
    _newsController.dispose();
    _fixesController.dispose();
    _managerVersionController.dispose();
    _managerBuildController.dispose();
    _managerReleaseNotesController.dispose();
    _githubOwnerController.dispose();
    _githubRepositoryController.dispose();
    _githubTokenController.dispose();
    _terminalScrollController.dispose();
    _projectAnalyzerSearchController.dispose();
    _gitHistorySearchController.dispose();
    super.dispose();
  }


  void _startGitHubOperation(String title, String detail, {bool determinate = false}) {
    setState(() {
      _githubOperationTitle = title;
      _githubOperationDetail = detail;
      _githubOperationProgress = determinate ? 0 : null;
      _githubOperationSentBytes = 0;
      _githubOperationTotalBytes = 0;
      _githubOperationSpeedBytesPerSecond = null;
      _githubOperationEta = null;
      _githubOperationStartedAt = DateTime.now();
      _githubLastProgressUpdate = null;
    });
  }

  void _setGitHubOperationDetail(String detail) {
    if (!mounted) return;
    setState(() => _githubOperationDetail = detail);
  }

  void _updateGitHubUploadProgress(int sentBytes, int totalBytes) {
    if (!mounted || totalBytes <= 0) return;
    final now = DateTime.now();
    final last = _githubLastProgressUpdate;
    if (sentBytes < totalBytes && last != null && now.difference(last).inMilliseconds < 100) {
      return;
    }
    final startedAt = _githubOperationStartedAt ?? now;
    final elapsedSeconds = now.difference(startedAt).inMilliseconds / 1000;
    final speed = elapsedSeconds > 0 ? sentBytes / elapsedSeconds : null;
    final remaining = totalBytes - sentBytes;
    final etaSeconds = speed != null && speed > 0 ? remaining / speed : null;
    setState(() {
      _githubLastProgressUpdate = now;
      _githubOperationSentBytes = sentBytes;
      _githubOperationTotalBytes = totalBytes;
      _githubOperationProgress = (sentBytes / totalBytes).clamp(0.0, 1.0).toDouble();
      _githubOperationSpeedBytesPerSecond = speed;
      _githubOperationEta = etaSeconds == null
          ? null
          : Duration(milliseconds: (etaSeconds * 1000).round());
      _githubOperationDetail = sentBytes >= totalBytes
          ? 'APK bolo odoslané. Čakám na potvrdenie GitHubu...'
          : 'Odosielam APK na GitHub...';
    });
  }

  void _finishGitHubOperation({required bool success, required String detail}) {
    if (!mounted) return;
    setState(() {
      _githubOperationDetail = detail;
      if (success && _githubOperationProgress != null) {
        _githubOperationProgress = 1;
      }
    });
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!mounted ||
          _githubTesting ||
          _githubUpdatingVersionJson ||
          _githubCreatingRelease ||
          _githubUploadingApk ||
          _githubPublishing) {
        return;
      }
      setState(() {
        _githubOperationTitle = null;
        _githubOperationDetail = null;
        _githubOperationProgress = null;
        _githubOperationSpeedBytesPerSecond = null;
        _githubOperationEta = null;
      });
    });
  }

  String _formatTransferSize(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} kB';
    return '$bytes B';
  }

  String _formatTransferSpeed(double bytesPerSecond) {
    return '${_formatTransferSize(bytesPerSecond.round())}/s';
  }

  String _formatEta(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 2) return 'menej ako 2 s';
    if (seconds < 60) return 'približne $seconds s';
    final minutes = (seconds / 60).ceil();
    return 'približne $minutes min';
  }

  Widget _buildGitHubOperationProgress() {
    final title = _githubOperationTitle;
    if (title == null) return const SizedBox.shrink();
    final progress = _githubOperationProgress;
    final percent = progress == null ? null : (progress * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (percent != null) Text('$percent %', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress, minHeight: 9, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 10),
          Text(_githubOperationDetail ?? 'Pracujem...'),
          if (_githubOperationTotalBytes > 0) ...<Widget>[
            const SizedBox(height: 8),
            Text('${_formatTransferSize(_githubOperationSentBytes)} z ${_formatTransferSize(_githubOperationTotalBytes)}'),
            if (_githubOperationSpeedBytesPerSecond != null)
              Text('Rýchlosť: ${_formatTransferSpeed(_githubOperationSpeedBytesPerSecond!)}'),
            if (_githubOperationEta != null && _githubOperationSentBytes < _githubOperationTotalBytes)
              Text('Zostávajúci čas: ${_formatEta(_githubOperationEta!)}'),
          ],
        ],
      ),
    );
  }

Future<void> _loadAppSettings() async {
  try {
    final settings = await _appSettingsService.load();
    if (!mounted) return;
    setState(() {
      _managerUpdateDownloadDirectory = settings.managerUpdateDirectory;
      _androidReleaseExportDirectory = settings.androidReleaseExportDirectory;
      _windowsReleaseExportDirectory = settings.windowsReleaseExportDirectory;
      _recentProjectPaths
        ..clear()
        ..addAll(settings.recentProjectPaths);
      _recentGitWorkspacePaths
        ..clear()
        ..addAll(settings.recentGitWorkspacePaths);
      _gitWorkspacePath = settings.lastGitWorkspacePath;
      _developerMode = settings.developerMode;
      final restoredPage = settings.lastSelectedPage.clamp(0, 11);
      _selectedPage = !_developerMode && <int>{4, 7, 8, 9, 10, 11}.contains(restoredPage)
          ? 0
          : restoredPage;
      _appSettingsLoading = false;
    });
    if (settings.lastGitWorkspacePath != null && await Directory(settings.lastGitWorkspacePath!).exists()) {
      _addLog('Obnovený posledný Git workspace: ${settings.lastGitWorkspacePath}');
      await _refreshGitWorkspace();
    }
    if (settings.androidReleaseExportDirectory != null) {
      _addLog('Predvolený priečinok pre Android APK Release: ${settings.androidReleaseExportDirectory}');
    }
    if (settings.windowsReleaseExportDirectory != null) {
      _addLog('Predvolený priečinok pre STAVBY PRO Windows Release: ${settings.windowsReleaseExportDirectory}');
    }
    if (settings.managerUpdateDirectory != null) {
      _addLog(
        'Predvolený priečinok pre aktualizačné ZIP: '
        '${settings.managerUpdateDirectory}',
      );
    }
    await _loadProjectProfiles();
  } catch (error) {
    if (!mounted) return;
    setState(() {
      _appSettingsLoading = false;
    });
    _addLog('Nastavenia aplikácie sa nepodarilo načítať: $error');
  }
}

Future<String?> _pickDirectorySafely({
  required String dialogTitle,
  String? savedDirectory,
  required String diagnosticStep,
}) async {
  final current = savedDirectory?.trim();
  final userProfile = Platform.environment['USERPROFILE'];
  final downloads = userProfile == null || userProfile.trim().isEmpty
      ? null
      : path.join(userProfile, 'Downloads');

  String? initialDirectory;
  if (current != null && current.isNotEmpty) {
    final exists = await Directory(current).exists();
    _addLog('$diagnosticStep – uložený priečinok: $current (existuje: $exists)');
    if (exists) initialDirectory = current;
  }
  if (initialDirectory == null && downloads != null) {
    final exists = await Directory(downloads).exists();
    _addLog('$diagnosticStep – záložný priečinok: $downloads (existuje: $exists)');
    if (exists) initialDirectory = downloads;
  }

  Future<String?> openPicker(String? initial) {
    return FilePicker.getDirectoryPath(
      dialogTitle: dialogTitle,
      initialDirectory: initial,
      lockParentWindow: true,
    );
  }

  try {
    _addLog('$diagnosticStep – otváram systémový výber priečinka.');
    final selected = await openPicker(initialDirectory);
    _addLog(selected == null
        ? '$diagnosticStep – výber bol zrušený.'
        : '$diagnosticStep – používateľ vybral: $selected');
    return selected;
  } catch (error, stackTrace) {
    _addLog('$diagnosticStep – prvý pokus zlyhal: $error');

    // Windows file_picker môže pri neplatnom alebo nedostupnom počiatočnom
    // priečinku vrátiť 0x80070002. Druhý pokus preto otvoríme bez initialDirectory.
    if (initialDirectory != null) {
      try {
        _addLog('$diagnosticStep – opakujem výber bez počiatočného priečinka.');
        final selected = await openPicker(null);
        _addLog(selected == null
            ? '$diagnosticStep – opakovaný výber bol zrušený.'
            : '$diagnosticStep – používateľ vybral: $selected');
        return selected;
      } catch (retryError, retryStackTrace) {
        await _writeCrashLog(
          retryError,
          retryStackTrace,
          step: '$diagnosticStep – opakovaný výber bez initialDirectory',
        );
        if (mounted) {
          _showError(
            'Systémový výber priečinka sa nepodarilo otvoriť. '
            'Skontroluj, či pôvodný priečinok alebo disk stále existuje.\n\n'
            'Chyba: $retryError',
          );
        }
        return null;
      }
    }

    await _writeCrashLog(error, stackTrace, step: diagnosticStep);
    if (mounted) {
      _showError('Systémový výber priečinka sa nepodarilo otvoriť: $error');
    }
    return null;
  }
}

Future<void> _chooseManagerUpdateDirectory() async {
  final selected = await _pickDirectorySafely(
    dialogTitle: 'Vyber predvolený priečinok pre RELEASE_MANAGER Export Release',
    savedDirectory: _managerUpdateDownloadDirectory,
    diagnosticStep: 'Výber RELEASE_MANAGER exportného priečinka',
  );
  if (selected == null || selected.trim().isEmpty) return;

  try {
    final directory = Directory(selected);
    if (!await directory.exists()) {
      _showError('Vybraný priečinok už neexistuje. Vyber iný priečinok.');
      return;
    }
    await _appSettingsService.saveManagerUpdateDirectory(selected);
    if (!mounted) return;
    setState(() {
      _managerUpdateDownloadDirectory = selected;
    });
    _addLog('Predvolený RELEASE_MANAGER Export Release priečinok bol uložený: $selected');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('RELEASE_MANAGER exportný priečinok bol uložený.'),
      ),
    );
  } catch (error, stackTrace) {
    await _writeCrashLog(
      error,
      stackTrace,
      step: 'Uloženie RELEASE_MANAGER exportného priečinka',
    );
    if (mounted) {
      _showError('Priečinok sa nepodarilo uložiť do nastavení: $error');
    }
  }
}



Future<void> _chooseWindowsReleaseExportDirectory() async {
  final current = _windowsReleaseExportDirectory?.trim();
  final userProfile = Platform.environment['USERPROFILE'];
  final fallback = userProfile == null || userProfile.trim().isEmpty
      ? null
      : path.join(userProfile, 'Downloads');
  final selected = await FilePicker.getDirectoryPath(
    dialogTitle: 'Vyber predvolený priečinok pre STAVBY PRO Windows Release',
    initialDirectory: current == null || current.isEmpty ? fallback : current,
    lockParentWindow: true,
  );
  if (selected == null || selected.trim().isEmpty) return;

  try {
    await _appSettingsService.saveWindowsReleaseExportDirectory(selected);
    if (!mounted) return;
    setState(() => _windowsReleaseExportDirectory = selected);
    _addLog('Predvolený priečinok pre STAVBY PRO Windows Release bol uložený: $selected');
    _showSuccess('Windows Release priečinok bol uložený.');
  } catch (error) {
    _showError('Windows Release priečinok sa nepodarilo uložiť: $error');
  }
}

Future<void> _chooseAndroidReleaseExportDirectory() async {
  final current = _androidReleaseExportDirectory?.trim();
  final userProfile = Platform.environment['USERPROFILE'];
  final fallback = userProfile == null || userProfile.trim().isEmpty
      ? null
      : path.join(userProfile, 'Downloads');
  final selected = await FilePicker.getDirectoryPath(
    dialogTitle: 'Vyber predvolený priečinok pre Android APK Release',
    initialDirectory: current == null || current.isEmpty ? fallback : current,
    lockParentWindow: true,
  );
  if (selected == null || selected.trim().isEmpty) return;

  try {
    await _appSettingsService.saveAndroidReleaseExportDirectory(selected);
    if (!mounted) return;
    setState(() => _androidReleaseExportDirectory = selected);
    _addLog('Predvolený priečinok pre Android APK Release bol uložený: $selected');
    _showSuccess('Android APK Release priečinok bol uložený.');
  } catch (error) {
    _showError('Android APK Release priečinok sa nepodarilo uložiť: $error');
  }
}

  Future<void> _loadGitHubSettings() async {
    try {
      final settings = await _githubSettingsService.load();
      if (!mounted) return;
      setState(() {
        _githubOwnerController.text = settings?.owner ?? 'marekmoravansky42';
        _githubRepositoryController.text =
            settings?.repository ?? 'stavby-pro-updates';
        _githubTokenController.text = settings?.token ?? '';
        _githubSettingsLoading = false;
        _githubConnected = false;
        _githubStatus = settings == null
            ? 'Vyplň token a otestuj pripojenie'
            : 'Nastavenie je uložené – vykonaj test pripojenia';
      });
      _addLog(settings == null
          ? 'GitHub nastavenie zatiaľ nie je uložené.'
          : 'GitHub nastavenie bolo bezpečne načítané.');
      if (settings?.isComplete == true) {
        unawaited(_saveAndTestGitHubConnection(silent: true));
      }
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Načítanie GitHub nastavenia',
      );
      if (!mounted) return;
      setState(() {
        _githubSettingsLoading = false;
        _githubConnected = false;
        _githubStatus = 'Nastavenie sa nepodarilo načítať: $error';
      });
      _addLog('Načítanie GitHub nastavenia zlyhalo: $error');
    }
  }

  GitHubSettings get _currentGitHubSettings => GitHubSettings(
        owner: _githubOwnerController.text.trim(),
        repository: _githubRepositoryController.text.trim(),
        token: _githubTokenController.text.trim(),
      );

  Future<void> _saveAndTestGitHubConnection({bool silent = false}) async {
    if (_githubTesting) return;
    final settings = _currentGitHubSettings;
    if (!settings.isComplete) {
      if (!silent) {
        _showError('Vyplň vlastníka, repozitár aj GitHub token.');
      }
      return;
    }
    _startGitHubOperation('Testujem GitHub pripojenie', 'Overujem token a dostupnosť repozitára...');
    setState(() {
      _githubTesting = true;
      _githubConnected = false;
      _githubStatus = 'Testujem pripojenie...';
    });
    _addLog('Testujem GitHub pripojenie pre ${settings.owner}/${settings.repository}...');
    try {
      final result = await _githubSettingsService.testConnection(settings);
      if (result.success) {
        await _githubSettingsService.save(settings);
      }
      if (!mounted) return;
      setState(() {
        _githubTesting = false;
        _githubConnected = result.success;
        _githubStatus = result.success
            ? '${result.message} ${result.repositoryFullName ?? ''} '
                '(${result.isPrivate == true ? 'súkromný' : 'verejný'} repozitár)'
            : result.message;
      });
      _finishGitHubOperation(success: result.success, detail: result.message);
      if (result.success) {
        _addLog('GitHub pripojenie je funkčné. Token bol uložený šifrovane cez Windows DPAPI.');
        if (!silent) {
          _showSuccess('GitHub pripojenie bolo úspešne otestované.');
        }
        unawaited(_checkForManagerUpdate(showDialogWhenAvailable: silent));
      } else {
        _addLog('GitHub test zlyhal: ${result.message}');
        if (!silent) {
          _showError(result.message);
        }
      }
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Uloženie a test GitHub pripojenia',
      );
      if (!mounted) return;
      setState(() {
        _githubTesting = false;
        _githubConnected = false;
        _githubStatus = 'Chyba: $error';
      });
      _finishGitHubOperation(success: false, detail: 'GitHub nastavenie sa nepodarilo otestovať.');
      _addLog('GitHub nastavenie zlyhalo: $error');
      if (!silent) {
        _showError('GitHub nastavenie sa nepodarilo uložiť alebo otestovať.');
      }
    }
  }

  Future<void> _checkForManagerUpdate({bool showDialogWhenAvailable = true}) async {
    if (_managerUpdateChecking || !_githubConnected) return;
    final settings = _currentGitHubSettings;
    setState(() {
      _managerUpdateChecking = true;
      _managerUpdateStatus = 'Kontrolujem dostupné verzie...';
    });
    _addLog('Kontrolujem aktualizáciu Release Managera na GitHube...');

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = Uri.https(
        'api.github.com',
        '/repos/${settings.owner}/STAVBY_PRO_RELEASE_MANAGER/releases',
        <String, String>{'per_page': '50'},
      );
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${settings.token}');
      request.headers.set(HttpHeaders.userAgentHeader, 'STAVBY-PRO-Release-Manager');
      request.headers.set('X-GitHub-Api-Version', '2022-11-28');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('GitHub vrátil HTTP ${response.statusCode}.');
      }
      final decoded = jsonDecode(body);
      if (decoded is! List) {
        throw const FormatException('GitHub vrátil neočakávaný formát zoznamu Release.');
      }

      String? latestVersion;
      int? latestBuild;
      String? latestUrl;
      String? latestDownloadUrl;
      String? latestAssetName;
      final tagPattern = RegExp(
        r'^release-manager-v(\d+)\.(\d+)\.(\d+)-build(\d+)$',
        caseSensitive: false,
      );

      for (final item in decoded) {
        if (item is! Map) continue;
        final data = Map<String, dynamic>.from(item);
        if (data['draft'] == true || data['prerelease'] == true) continue;
        final match = tagPattern.firstMatch(data['tag_name']?.toString() ?? '');
        if (match == null) continue;
        final candidateVersion = '${match.group(1)}.${match.group(2)}.${match.group(3)}';
        final candidateBuild = int.parse(match.group(4)!);
        if (latestVersion == null ||
            _compareManagerVersions(candidateVersion, candidateBuild, latestVersion, latestBuild!) > 0) {
          latestVersion = candidateVersion;
          latestBuild = candidateBuild;
          latestUrl = data['html_url']?.toString();
          latestDownloadUrl = null;
          latestAssetName = null;
          final assets = data['assets'];
          if (assets is List) {
            for (final asset in assets) {
              if (asset is! Map) continue;
              final assetData = Map<String, dynamic>.from(asset);
              final name = assetData['name']?.toString() ?? '';
              final downloadUrl = assetData['browser_download_url']?.toString();
              if (name.toLowerCase().endsWith('.zip') &&
                  downloadUrl != null &&
                  downloadUrl.isNotEmpty) {
                latestAssetName = name;
                latestDownloadUrl = downloadUrl;
                break;
              }
            }
          }
        }
      }

      if (!mounted) return;
      const currentVersion = ReleaseManagerVersion.version;
      const currentBuild = ReleaseManagerVersion.build;
      final available = latestVersion != null &&
          _compareManagerVersions(latestVersion, latestBuild!, currentVersion, currentBuild) > 0;
      setState(() {
        _managerUpdateChecking = false;
        _latestManagerVersion = latestVersion;
        _latestManagerBuild = latestBuild;
        _latestManagerReleaseUrl = latestUrl;
        _latestManagerDownloadUrl = latestDownloadUrl;
        _latestManagerAssetName = latestAssetName;
        _managerUpdateStatus = latestVersion == null
            ? 'V repozitári zatiaľ nie je publikovaný Release Manager.'
            : available
                ? 'Dostupná verzia $latestVersion Build $latestBuild'
                : 'Používaš najnovšiu verziu.';
      });
      _addLog(_managerUpdateStatus);
      if (available && showDialogWhenAvailable) {
        await _showManagerUpdateDialog();
      }
    } catch (error, stackTrace) {
      await _writeCrashLog(error, stackTrace, step: 'Kontrola aktualizácie Release Managera');
      if (!mounted) return;
      setState(() {
        _managerUpdateChecking = false;
        _managerUpdateStatus = 'Kontrola aktualizácie zlyhala: $error';
      });
      _addLog(_managerUpdateStatus);
    } finally {
      client.close(force: true);
    }
  }

  int _compareManagerVersions(
    String leftVersion,
    int leftBuild,
    String rightVersion,
    int rightBuild,
  ) {
    final left = leftVersion.split('.').map(int.parse).toList();
    final right = rightVersion.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      final comparison = left[i].compareTo(right[i]);
      if (comparison != 0) return comparison;
    }
    return leftBuild.compareTo(rightBuild);
  }

  Future<void> _showManagerUpdateDialog() async {
    final version = _latestManagerVersion;
    final build = _latestManagerBuild;
    if (!mounted || version == null || build == null) return;
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dostupná nová verzia'),
        content: Text(
          'Aktuálna verzia:\n${ReleaseManagerVersion.label}\n\n'
          'Najnovšia verzia:\n$version Build $build\n\n'
          '${_latestManagerDownloadUrl == null ? 'ZIP balík nebol v Release nájdený.' : 'Aktualizačný ZIP je pripravený na stiahnutie.'}',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('later'),
            child: const Text('PRIPOMENÚŤ NESKÔR'),
          ),
          OutlinedButton.icon(
            onPressed: _latestManagerReleaseUrl == null
                ? null
                : () => Navigator.of(dialogContext).pop('release'),
            icon: const Icon(Icons.open_in_new),
            label: const Text('OTVORIŤ RELEASE'),
          ),
          FilledButton.icon(
            onPressed: _latestManagerDownloadUrl == null
                ? null
                : () => Navigator.of(dialogContext).pop('download'),
            icon: const Icon(Icons.download),
            label: const Text('STIAHNUŤ AKTUALIZÁCIU'),
          ),
        ],
      ),
    );
    if (action == 'release' && _latestManagerReleaseUrl != null) {
      await _openExternalUrl(_latestManagerReleaseUrl!);
    } else if (action == 'download') {
      await _downloadManagerUpdate();
    }
  }

  Future<void> _downloadManagerUpdate() async {
    if (_managerUpdateDownloading) return;
    final downloadUrl = _latestManagerDownloadUrl;
    final assetName = _latestManagerAssetName;
    if (downloadUrl == null || assetName == null) {
      _showError('Aktualizačný ZIP nie je dostupný.');
      return;
    }

    var downloadDirectory = _managerUpdateDownloadDirectory?.trim();
    if (downloadDirectory == null || downloadDirectory.isEmpty) {
      await _chooseManagerUpdateDirectory();
      downloadDirectory = _managerUpdateDownloadDirectory?.trim();
      if (downloadDirectory == null || downloadDirectory.isEmpty) {
        _addLog(
          'Sťahovanie aktualizácie bolo zrušené – predvolený priečinok '
          'nebol nastavený.',
        );
        return;
      }
    }

    var selectedDirectory = Directory(downloadDirectory);
    if (!await selectedDirectory.exists()) {
      _addLog(
        'Uložený priečinok už neexistuje. Vyber nový predvolený priečinok.',
      );
      if (mounted) {
        setState(() {
          _managerUpdateDownloadDirectory = null;
        });
      }
      await _appSettingsService.clearManagerUpdateDirectory();
      await _chooseManagerUpdateDirectory();
      downloadDirectory = _managerUpdateDownloadDirectory?.trim();
      if (downloadDirectory == null || downloadDirectory.isEmpty) {
        _addLog('Sťahovanie aktualizácie bolo zrušené.');
        return;
      }
      selectedDirectory = Directory(downloadDirectory);
      if (!await selectedDirectory.exists()) {
        await selectedDirectory.create(recursive: true);
      }
    }
    final target = File(path.join(selectedDirectory.path, assetName));
    if (await target.exists()) {
      if (!mounted) return;
      final overwrite = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Súbor už existuje'),
          content: Text(
            '$assetName už je v priečinku ${selectedDirectory.path}. '
            'Nahradiť ho?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ZRUŠIŤ'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('NAHRADIŤ'),
            ),
          ],
        ),
      );
      if (overwrite != true) return;
      await target.delete();
    }

    setState(() {
      _managerUpdateDownloading = true;
    });
    _addLog('Sťahujem aktualizáciu Release Managera: $assetName');
    _addLog('Zdroj aktualizácie: $downloadUrl');

    Object? dartDownloadError;
    StackTrace? dartDownloadStackTrace;
    try {
      try {
        await _downloadManagerUpdateWithHttpClient(
          downloadUrl: downloadUrl,
          target: target,
        );
      } catch (error, stackTrace) {
        dartDownloadError = error;
        dartDownloadStackTrace = stackTrace;
        if (await target.exists()) {
          try {
            await target.delete();
          } catch (_) {}
        }
        _addLog(
          'Priame HTTPS sťahovanie zlyhalo: $error. '
          'Skúšam systémové sťahovanie cez PowerShell.',
        );
        await _downloadManagerUpdateWithPowerShell(
          downloadUrl: downloadUrl,
          target: target,
        );
      }

      if (!await target.exists() || await target.length() == 0) {
        throw StateError('Stiahnutý ZIP je prázdny alebo chýba.');
      }
      _addLog('Aktualizácia stiahnutá: ${target.path}');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Aktualizácia stiahnutá'),
          content: SelectableText(
            'ZIP balík bol uložený do:\n\n${target.path}\n\n'
            'Ukonči Release Manager, rozbaľ ZIP do nového priečinka a spusti novú verziu.',
          ),
          actions: <Widget>[
            OutlinedButton.icon(
              onPressed: () => Process.start(
                'explorer.exe',
                <String>['/select,', target.path],
                runInShell: false,
              ),
              icon: const Icon(Icons.folder_open),
              label: const Text('OTVORIŤ PRIEČINOK'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('HOTOVO'),
            ),
          ],
        ),
      );
    } catch (error, stackTrace) {
      if (await target.exists()) {
        try {
          await target.delete();
        } catch (_) {}
      }
      final diagnosticError = dartDownloadError == null
          ? error
          : StateError(
              'Priame HTTPS sťahovanie zlyhalo: $dartDownloadError\n'
              'Systémové sťahovanie cez PowerShell zlyhalo: $error',
            );
      final diagnosticStackTrace = dartDownloadStackTrace ?? stackTrace;
      await _writeCrashLog(
        diagnosticError,
        diagnosticStackTrace,
        step: 'Sťahovanie aktualizácie Release Managera',
      );
      _addLog('CHYBA sťahovania aktualizácie: $diagnosticError');
      if (mounted) {
        _showError(
          'Aktualizáciu sa nepodarilo stiahnuť ani systémovým '
          'sťahovaním: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _managerUpdateDownloading = false;
        });
      }
    }
  }

  Future<void> _downloadManagerUpdateWithHttpClient({
    required String downloadUrl,
    required File target,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 30);
    IOSink? sink;
    try {
      final request = await client.getUrl(Uri.parse(downloadUrl));
      request.followRedirects = true;
      request.maxRedirects = 10;
      request.headers.set(HttpHeaders.acceptHeader, 'application/octet-stream');
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'STAVBY-PRO-Release-Manager/${ReleaseManagerVersion.version}',
      );
      final response = await request.close();
      _addLog(
        'HTTP odpoveď: ${response.statusCode}, '
        'cieľová URL: ${response.redirects.isEmpty ? downloadUrl : response.redirects.last.location}',
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Sťahovanie zlyhalo: HTTP ${response.statusCode}.',
          uri: Uri.parse(downloadUrl),
        );
      }

      sink = target.openWrite();
      await for (final chunk in response) {
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      sink = null;
    } finally {
      try {
        await sink?.close();
      } catch (_) {}
      client.close(force: false);
    }
  }

  Future<void> _downloadManagerUpdateWithPowerShell({
    required String downloadUrl,
    required File target,
  }) async {
    final source = _powershellLiteral(downloadUrl);
    final destination = _powershellLiteral(target.path);
    final script = <String>[
      r"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12",
      r"$ProgressPreference = 'SilentlyContinue'",
      "\$headers = @{ 'User-Agent' = 'STAVBY-PRO-Release-Manager/${ReleaseManagerVersion.version}'; 'Accept' = 'application/octet-stream' }",
      "Invoke-WebRequest -UseBasicParsing -Uri '$source' -OutFile '$destination' -Headers \$headers -MaximumRedirection 10",
    ].join('; ');

    final result = await Process.run(
      'powershell.exe',
      <String>[
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
      ],
      runInShell: false,
    );

    if (result.exitCode != 0) {
      throw StateError(
        'PowerShell vrátil kód ${result.exitCode}: ${result.stderr}',
      );
    }
    _addLog('Aktualizácia bola stiahnutá systémovým HTTPS klientom Windows.');
  }

  Future<void> _updateVersionJsonOnGitHub() async {
    if (_githubUpdatingVersionJson) return;
    if (!_githubConnected) {
      _showError('Najprv úspešne otestuj GitHub pripojenie.');
      return;
    }

    String jsonText;
    try {
      jsonText = _buildVersionJson();
    } on FormatException catch (error) {
      _showError(error.message);
      _addLog('CHYBA: ${error.message}');
      return;
    }

    final settings = _currentGitHubSettings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aktualizovať version.json na GitHube?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Repozitár: ${settings.owner}/${settings.repository}\n'
                'Súbor: version.json\n\n'
                'Existujúci súbor bude nahradený týmto obsahom:',
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 260),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonText,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ZRUŠIŤ'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('AKTUALIZOVAŤ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _startGitHubOperation(
      'Aktualizujem version.json',
      'Načítavam aktuálny súbor z GitHubu...',
    );
    setState(() {
      _githubUpdatingVersionJson = true;
      _versionJsonPreview = jsonText;
    });
    _addLog(
      'Aktualizujem version.json v ${settings.owner}/${settings.repository}...',
    );

    try {
      _setGitHubOperationDetail('Zapisujem nový obsah version.json do repozitára...');
      final result = await _githubSettingsService.updateVersionJson(
        settings: settings,
        jsonContent: jsonText,
      );
      if (!mounted) return;
      setState(() => _githubUpdatingVersionJson = false);
      _finishGitHubOperation(success: result.success, detail: result.message);
      if (result.success) {
        final shortSha = result.commitSha?.split('').take(7).join();
        _addLog(
          '${result.message}${shortSha == null ? '' : ' Commit: $shortSha'}',
        );
        _showSuccess(result.message);
      } else {
        _addLog('GitHub aktualizácia zlyhala: ${result.message}');
        _showError(result.message);
      }
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: '3. Aktualizovať version.json samostatne na GitHube',
        projectPath: _project?.projectPath,
      );
      if (!mounted) return;
      setState(() => _githubUpdatingVersionJson = false);
      _finishGitHubOperation(success: false, detail: '3. Aktualizovať version.json samostatne na GitHube zlyhala.');
      _addLog('3. Aktualizovať version.json samostatne na GitHube zlyhala: $error');
      _showError('3. Aktualizovať version.json samostatne na GitHube zlyhala.');
    }
  }

  Future<void> _createGitHubRelease() async {
    if (_githubCreatingRelease) return;
    if (!_githubConnected) {
      _showError('Najprv úspešne otestuj GitHub pripojenie.');
      return;
    }

    final project = _project;
    if (project == null) {
      _showError('Najprv otvor projekt STAVBY PRO.');
      return;
    }

    String releaseBody;
    try {
      releaseBody = _buildGithubRelease();
    } on FormatException catch (error) {
      _showError(error.message);
      _addLog('CHYBA: ${error.message}');
      return;
    }

    final settings = _currentGitHubSettings;
    final tagName = 'v${project.version}';
    final releaseName = 'STAVBY PRO ${project.version}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vytvoriť GitHub Release?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Repozitár: ${settings.owner}/${settings.repository}\n'
                'Tag: $tagName\n'
                'Názov: $releaseName\n\n'
                'Vytvorí sa verejný GitHub Release. APK sa v tejto verzii ešte nenahrá.',
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 260),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    releaseBody,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ZRUŠIŤ'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.new_releases_outlined),
            label: const Text('VYTVORIŤ RELEASE'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _startGitHubOperation(
      'Vytváram GitHub Release',
      'Kontrolujem, či tag a Release ešte neexistujú...',
    );
    setState(() {
      _githubCreatingRelease = true;
      _githubReleasePreview = releaseBody;
    });
    _addLog('Vytváram GitHub Release $tagName...');

    try {
      _setGitHubOperationDetail('Vytváram tag a verejný GitHub Release...');
      final result = await _githubSettingsService.createRelease(
        settings: settings,
        tagName: tagName,
        releaseName: releaseName,
        body: releaseBody,
      );
      if (!mounted) return;
      setState(() => _githubCreatingRelease = false);
      _finishGitHubOperation(success: result.success, detail: result.message);
      if (result.success) {
        _addLog(
          '${result.message}${result.releaseUrl == null ? '' : ' ${result.releaseUrl}'}',
        );
        _showSuccess(result.message);
      } else {
        _addLog('4. Vytvoriť GitHub Release samostatne zlyhalo: ${result.message}');
        _showError(result.message);
      }
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: '4. Vytvoriť GitHub Release samostatne',
        projectPath: _project?.projectPath,
      );
      if (!mounted) return;
      setState(() => _githubCreatingRelease = false);
      _finishGitHubOperation(success: false, detail: '4. Vytvoriť GitHub Release samostatne zlyhalo.');
      _addLog('4. Vytvoriť GitHub Release samostatne zlyhalo: $error');
      _showError('4. Vytvoriť GitHub Release samostatne zlyhalo.');
    }
  }


  Future<void> _uploadApkToGitHubRelease() async {
    if (_githubUploadingApk) return;
    if (!_githubConnected) {
      _showError('Najprv úspešne otestuj GitHub pripojenie.');
      return;
    }
    final project = _project;
    final apkPath = _apkPath;
    if (project == null || apkPath == null || _apkSha256 == null) {
      _showError('Najprv otvor projekt a analyzuj release APK.');
      return;
    }

    final apkFile = File(apkPath);
    final apkName = path.basename(apkPath);
    final apkUrl = _apkUrlController.text.trim();
    if (apkUrl.isNotEmpty) {
      final urlName = path.basename(Uri.parse(apkUrl).path);
      if (urlName.isNotEmpty && urlName != apkName) {
        _showError('Názov APK ($apkName) sa nezhoduje s názvom v URL version.json ($urlName).');
        return;
      }
    }

    final tagName = 'v${project.version}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nahrať APK do GitHub Release?'),
        content: Text(
          'Repozitár: ${_currentGitHubSettings.owner}/${_currentGitHubSettings.repository}\n'
          'Tag: $tagName\n'
          'APK: $apkName\n'
          'Veľkosť: ${_formatMb(_apkSizeBytes ?? 0)} MB\n\n'
          'Ak už APK s rovnakým názvom existuje, aplikácia ponúkne jeho bezpečné nahradenie.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ZRUŠIŤ'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.upload_file),
            label: const Text('NAHRAŤ APK'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _startGitHubOperation('Nahrávanie APK na GitHub', 'Kontrolujem GitHub Release a duplicitný názov...', determinate: true);
    setState(() => _githubUploadingApk = true);
    _addLog('Nahrávam APK $apkName do GitHub Release $tagName...');
    try {
      final result = await _githubSettingsService.uploadReleaseAsset(
        settings: _currentGitHubSettings,
        tagName: tagName,
        file: apkFile,
        onProgress: _updateGitHubUploadProgress,
      );
      if (!mounted) return;
      setState(() => _githubUploadingApk = false);
      _finishGitHubOperation(success: result.success, detail: result.message);
      if (result.success) {
        _addLog('${result.message} Súbor: ${result.assetName ?? apkName}');
        _showSuccess(result.message);
      } else if (result.alreadyExists) {
        _finishGitHubOperation(
          success: false,
          detail: 'APK už existuje. Čakám na rozhodnutie používateľa.',
        );
        final replace = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('APK už existuje'),
            content: Text(
              'V GitHub Release už existuje súbor:\n\n'
              '$apkName\n\n'
              'Chceš staré APK odstrániť a nahradiť ho aktuálnym súborom?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('ZRUŠIŤ'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.sync),
                label: const Text('NAHRADIŤ APK'),
              ),
            ],
          ),
        );
        if (replace == true && mounted) {
          _startGitHubOperation(
            'Nahradenie APK na GitHube',
            'Odstraňujem staré APK a pripravujem nové nahrávanie...',
            determinate: true,
          );
          setState(() => _githubUploadingApk = true);
          _addLog('Nahrádzam existujúce APK $apkName v GitHub Release $tagName...');
          final replacement = await _githubSettingsService.uploadReleaseAsset(
            settings: _currentGitHubSettings,
            tagName: tagName,
            file: apkFile,
            overwriteExisting: true,
            onProgress: _updateGitHubUploadProgress,
          );
          if (!mounted) return;
          setState(() => _githubUploadingApk = false);
          _finishGitHubOperation(success: replacement.success, detail: replacement.message);
          if (replacement.success) {
            _addLog('${replacement.message} Súbor: ${replacement.assetName ?? apkName}');
            _showSuccess('Existujúce APK bolo úspešne nahradené.');
          } else {
            _addLog('Nahradenie APK zlyhalo: ${replacement.message}');
            _showError(replacement.message);
          }
        } else {
          _addLog('Nahradenie existujúceho APK bolo zrušené používateľom.');
        }
      } else {
        _addLog('Nahratie APK zlyhalo: ${result.message}');
        _showError(result.message);
      }
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: '5. Nahrať APK samostatne',
        projectPath: _project?.projectPath,
      );
      if (!mounted) return;
      setState(() => _githubUploadingApk = false);
      _finishGitHubOperation(success: false, detail: '5. Nahrať APK samostatne zlyhalo.');
      _addLog('5. Nahrať APK samostatne zlyhalo: $error');
      _showError('5. Nahrať APK samostatne zlyhalo.');
    }
  }

  String _publishedApkName(ProjectInfo project) =>
      '${project.releaseFileStem}.apk';

  String _publishedApkUrl(
    GitHubSettings settings,
    ProjectInfo project,
    String assetName,
  ) =>
      'https://github.com/${settings.owner}/${settings.repository}/releases/download/'
      'v${project.version}/$assetName';

  Future<void> _publishToGitHub() async {
    if (_githubPublishing) return;
    if (!_githubConnected) {
      _showError('Najprv úspešne otestuj GitHub pripojenie.');
      return;
    }

    final project = _project;
    final apkPath = _apkPath;
    if (project == null || apkPath == null || _apkSha256 == null) {
      _showError('Najprv otvor projekt a analyzuj release APK.');
      return;
    }

    final settings = _currentGitHubSettings;
    final apkFile = File(apkPath);
    final assetName = _publishedApkName(project);
    final tagName = 'v${project.version}';
    final releaseName = 'STAVBY PRO ${project.version}';
    final assetUrl = _publishedApkUrl(settings, project, assetName);

    String releaseBody;
    String versionJson;
    try {
      _apkUrlController.text = assetUrl;
      _apkUrlController.selection = TextSelection.collapsed(offset: assetUrl.length);
      versionJson = _buildVersionJson();
      releaseBody = _buildGithubRelease();
    } on FormatException catch (error) {
      _showError(error.message);
      _addLog('CHYBA: ${error.message}');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Publikovať celé vydanie na GitHub?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Repozitár: ${settings.owner}/${settings.repository}\n'
                  'Tag: $tagName\n'
                  'Release: $releaseName\n'
                  'APK: $assetName\n'
                  'Veľkosť: ${_formatMb(_apkSizeBytes ?? 0)} MB\n\n'
                  'Aplikácia aktualizuje version.json, vytvorí alebo použije '
                  'GitHub Release a nahrá APK. Ak rovnaké APK už existuje, '
                  'pred nahradením si vyžiada potvrdenie.',
                ),
                const SizedBox(height: 12),
                SelectableText(
                  'URL APK:\n$assetUrl',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ZRUŠIŤ'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.rocket_launch_outlined),
            label: const Text('PUBLIKOVAŤ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final publishStopwatch = Stopwatch()..start();
    setState(() {
      _githubPublishing = true;
      _versionJsonPreview = versionJson;
      _githubReleasePreview = releaseBody;
    });
    _startGitHubOperation(
      'Publikovanie na GitHub',
      'Krok 1 z 3: aktualizujem version.json...',
    );
    _addLog('=== ZAČÍNA PUBLIKOVANIE $releaseName NA GITHUB ===');

    try {
      final versionResult = await _githubSettingsService.updateVersionJson(
        settings: settings,
        jsonContent: versionJson,
      );
      if (!versionResult.success) {
        throw StateError(versionResult.message);
      }
      _addLog(versionResult.message);

      _setGitHubOperationDetail('Krok 2 z 3: vytváram alebo kontrolujem GitHub Release...');
      final releaseResult = await _githubSettingsService.createRelease(
        settings: settings,
        tagName: tagName,
        releaseName: releaseName,
        body: releaseBody,
      );
      if (!releaseResult.success && !releaseResult.alreadyExists) {
        throw StateError(releaseResult.message);
      }
      _addLog(releaseResult.alreadyExists
          ? 'GitHub Release $tagName už existuje, použijem ho.'
          : releaseResult.message);

      _startGitHubOperation(
        'Publikovanie na GitHub',
        'Krok 3 z 3: nahrávam $assetName...',
        determinate: true,
      );
      var uploadResult = await _githubSettingsService.uploadReleaseAsset(
        settings: settings,
        tagName: tagName,
        file: apkFile,
        assetName: assetName,
        onProgress: _updateGitHubUploadProgress,
      );

      if (uploadResult.alreadyExists && mounted) {
        _finishGitHubOperation(
          success: false,
          detail: 'APK už existuje. Čakám na potvrdenie nahradenia.',
        );
        final replace = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('APK už existuje'),
            content: Text(
              'V GitHub Release už existuje súbor:\n\n'
              '$assetName\n\n'
              'Chceš ho odstrániť a nahradiť aktuálnym APK?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('ZRUŠIŤ'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.sync),
                label: const Text('NAHRADIŤ APK'),
              ),
            ],
          ),
        );
        if (replace != true) {
          throw const FormatException('Publikovanie bolo zrušené pred nahradením existujúceho APK.');
        }
        _startGitHubOperation(
          'Publikovanie na GitHub',
          'Krok 3 z 3: nahrádzam $assetName...',
          determinate: true,
        );
        uploadResult = await _githubSettingsService.uploadReleaseAsset(
          settings: settings,
          tagName: tagName,
          file: apkFile,
          assetName: assetName,
          overwriteExisting: true,
          onProgress: _updateGitHubUploadProgress,
        );
      }

      if (!uploadResult.success) {
        throw StateError(uploadResult.message);
      }
      if (!mounted) return;
      setState(() => _githubPublishing = false);
      _finishGitHubOperation(
        success: true,
        detail: 'Publikovanie bolo úspešne dokončené. APK: $assetName',
      );
      _addLog('${uploadResult.message} URL: $assetUrl');
      _addLog('=== PUBLIKOVANIE BOLO ÚSPEŠNE DOKONČENÉ ===');
      publishStopwatch.stop();
      final releaseUrl =
          'https://github.com/${settings.owner}/${settings.repository}/releases/tag/$tagName';
      final elapsedSeconds =
          (publishStopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline),
          title: const Text('Publikovanie dokončené'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _publicationResultRow(
                    Icons.check_circle,
                    'version.json bol aktualizovaný',
                  ),
                  _publicationResultRow(
                    Icons.check_circle,
                    'GitHub Release je pripravený',
                  ),
                  _publicationResultRow(
                    Icons.check_circle,
                    'APK bolo úspešne nahrané',
                  ),
                  const Divider(height: 28),
                  SelectableText(
                    'Verzia: ${project.version}\n'
                    'Build: ${project.releaseBuild}\n'
                    'APK: $assetName\n'
                    'Celkový čas: $elapsedSeconds s\n\n'
                    'GitHub Release:\n$releaseUrl',
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: releaseUrl));
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Odkaz bol skopírovaný.')),
                );
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('KOPÍROVAŤ ODKAZ'),
            ),
            OutlinedButton.icon(
              onPressed: () => _openExternalUrl(releaseUrl),
              icon: const Icon(Icons.open_in_new),
              label: const Text('OTVORIŤ RELEASE'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('HOTOVO'),
            ),
          ],
        ),
      );
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: '2. Publikovať celé vydanie na GitHub',
        projectPath: project.projectPath,
      );
      if (!mounted) return;
      setState(() => _githubPublishing = false);
      final message = error is FormatException
          ? error.message
          : error.toString().replaceFirst('Bad state: ', '');
      _finishGitHubOperation(success: false, detail: message);
      _addLog('Publikovanie na GitHub zlyhalo: $message');
      _showError(message);
    }
  }

  Widget _publicationResultRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }


  Future<void> _selectManagerProjectDirectory() async {
    if (_managerBuildRunning) return;
    _addLog('Otváram výber zdrojového projektu Release Managera...');
    String? selectedPath;
    try {
      selectedPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Vyber koreňový priečinok projektu Release Managera',
      );
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Výber projektu Release Managera',
      );
      if (mounted) {
        _showError('Výber projektu zlyhal: $error');
      }
      return;
    }

    if (selectedPath == null) {
      _addLog('Výber projektu Release Managera bol zrušený.');
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    try {
      final pubspec = File(path.join(selectedPath, 'pubspec.yaml'));
      final windowsDirectory = Directory(path.join(selectedPath, 'windows'));
      if (!await pubspec.exists() || !await windowsDirectory.exists()) {
        _showError(
          'Vybraný priečinok nie je platný Flutter Windows projekt. '
          'Musí obsahovať pubspec.yaml a priečinok windows.',
        );
        return;
      }

      final pubspecText = await pubspec.readAsString();
      final versionMatch = RegExp(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$', multiLine: true)
          .firstMatch(pubspecText);
      setState(() {
        _managerProjectPath = selectedPath;
        _managerReleaseDirectoryPath = null;
        _managerPackagePath = null;
        _managerBuildSucceeded = false;
        if (versionMatch != null) {
          _managerVersionController.text = versionMatch.group(1)!;
          _managerBuildController.text = versionMatch.group(2)!;
        }
      });
      _addLog('Vybraný projekt Release Managera: $selectedPath');
      if (versionMatch != null) {
        _addLog('Načítaná verzia projektu: ${versionMatch.group(1)} Build ${versionMatch.group(2)}');
      }
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Overenie projektu Release Managera',
        projectPath: selectedPath,
      );
      if (mounted) {
        _showError('Projekt sa nepodarilo overiť: $error');
      }
    }
  }


  String _diagnosticTimeStamp(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}_'
        '${two(value.hour)}-${two(value.minute)}-${two(value.second)}';
  }

  String _buildFailureHint(String output) {
    final lower = output.toLowerCase();
    if (lower.contains("member not found") ||
        lower.contains("isn't defined for the type") ||
        lower.contains('undefined_getter')) {
      return 'Pravdepodobná príčina: nekompatibilné API balíka alebo nesprávny názov metódy či vlastnosti.';
    }
    if (lower.contains("target of uri doesn't exist") ||
        lower.contains('could not find package') ||
        lower.contains('not found in pubspec')) {
      return 'Pravdepodobná príčina: chýbajúci import alebo závislosť v pubspec.yaml.';
    }
    if (lower.contains('version solving failed') ||
        lower.contains('because every version')) {
      return 'Pravdepodobná príčina: konflikt verzií závislostí.';
    }
    if (lower.contains('access is denied') ||
        lower.contains('permission denied') ||
        lower.contains('being used by another process')) {
      return 'Pravdepodobná príčina: súbor používa iný proces alebo Windows odmietol prístup.';
    }
    if (lower.contains('no space left') ||
        lower.contains('not enough space')) {
      return 'Pravdepodobná príčina: nedostatok voľného miesta na disku.';
    }
    if (lower.contains('flutter') && lower.contains('not recognized')) {
      return 'Pravdepodobná príčina: Flutter nie je dostupný v systémovej premennej PATH.';
    }
    if (lower.contains('cmake') ||
        lower.contains('msbuild') ||
        lower.contains('visual studio')) {
      return 'Pravdepodobná príčina: chyba Windows toolchainu, CMake alebo Visual Studia.';
    }
    if (lower.contains('some tests failed') ||
        lower.contains('test failed')) {
      return 'Pravdepodobná príčina: najmenej jeden automatický test neprešiel.';
    }
    return 'Presná príčina je uvedená v zachytenom výstupe nižšie.';
  }

  String _buildDiagnosticReport({
    required String projectName,
    required String projectPath,
    required String label,
    required List<String> arguments,
    required List<String> output,
    int? exitCode,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final now = DateTime.now();
    final selectedOutput = output.length > 250
        ? output.sublist(output.length - 250)
        : output;
    final outputText = selectedOutput.isEmpty
        ? '(Príkaz neposkytol žiadny textový výstup.)'
        : selectedOutput.join('\n');

    return (StringBuffer()
      ..writeln('STAVBY PRO RELEASE MANAGER – DIAGNOSTICKÝ REPORT')
      ..writeln('============================================================')
      ..writeln('Verzia Release Managera: ${ReleaseManagerVersion.label}')
      ..writeln('Dátum a čas: ${now.toIso8601String()}')
      ..writeln('Operačný systém: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}')
      ..writeln('Projekt: $projectName')
      ..writeln('Cesta projektu: $projectPath')
      ..writeln('Krok: $label')
      ..writeln('Príkaz: flutter ${arguments.join(' ')}')
      ..writeln('Návratový kód: ${exitCode ?? 'nedostupný'}')
      ..writeln()
      ..writeln(_buildFailureHint(outputText))
      ..writeln()
      ..writeln('CHYBA:')
      ..writeln(error ?? 'Príkaz skončil neúspešným návratovým kódom.')
      ..writeln()
      ..writeln('POSLEDNÝCH ${selectedOutput.length} RIADKOV VÝSTUPU:')
      ..writeln('------------------------------------------------------------')
      ..writeln(outputText)
      ..writeln()
      ..writeln('STACK TRACE:')
      ..writeln(stackTrace ?? '(Stack trace nie je k dispozícii.)')
      ..writeln()
      ..writeln('POSLEDNÝCH 100 RIADKOV ŽIVÉHO TERMINÁLU:')
      ..writeln('------------------------------------------------------------')
      ..writeln(
        _diagnostics.tail(100).join('\n'),
      ))
        .toString();
  }

  Future<File> _saveDiagnosticReport({
    required String projectPath,
    required String report,
  }) async {
    final diagnosticsDirectory = Directory(
      path.join(projectPath, 'diagnostics'),
    );
    await diagnosticsDirectory.create(recursive: true);
    final file = File(
      path.join(
        diagnosticsDirectory.path,
        'BUILD_ERROR_${_diagnosticTimeStamp(DateTime.now())}.txt',
      ),
    );
    await file.writeAsString(report, flush: true);
    return file;
  }

  Future<void> _copyDiagnosticReport(String report) async {
    await Clipboard.setData(ClipboardData(text: report));
    _addLog('Diagnostický report bol skopírovaný do schránky.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report je v schránke. V ChatGPT ho vlož pomocou Ctrl + V.',
          ),
        ),
      );
    }
  }

  Future<void> _saveDiagnosticReportAs(String report) async {
    final outputPath = await FilePicker.saveFile(
      dialogTitle: 'Uložiť diagnostický report',
      fileName:
          'BUILD_ERROR_${_diagnosticTimeStamp(DateTime.now())}.txt',
      type: FileType.custom,
      allowedExtensions: const <String>['txt'],
    );
    if (outputPath == null) return;
    final normalizedPath =
        outputPath.toLowerCase().endsWith('.txt') ? outputPath : '$outputPath.txt';
    await File(normalizedPath).writeAsString(report, flush: true);
    _addLog('Diagnostický report bol uložený: $normalizedPath');
  }

  Future<File> _exportDiagnosticPackage({
    required String projectPath,
    required String report,
  }) async {
    final diagnosticsRoot = Directory(path.join(projectPath, 'diagnostics'));
    await diagnosticsRoot.create(recursive: true);
    final stamp = _diagnosticTimeStamp(DateTime.now());
    final packageDirectory = Directory(
      path.join(diagnosticsRoot.path, 'Diagnostics_$stamp'),
    );
    await packageDirectory.create(recursive: true);

    await File(path.join(packageDirectory.path, 'build_error_report.txt'))
        .writeAsString(report, flush: true);
    await File(path.join(packageDirectory.path, 'terminal.log'))
        .writeAsString(_diagnostics.exportText(), flush: true);
    await File(path.join(packageDirectory.path, 'system_info.txt')).writeAsString(
      'Release Manager: ${ReleaseManagerVersion.label}\n'
      'OS: ${Platform.operatingSystem}\n'
      'OS version: ${Platform.operatingSystemVersion}\n'
      'Locale: ${Platform.localeName}\n'
      'Processors: ${Platform.numberOfProcessors}\n'
      'Executable: ${Platform.resolvedExecutable}\n'
      'Project: $projectPath\n',
      flush: true,
    );

    for (final filename in <String>['pubspec.yaml', 'pubspec.lock']) {
      final source = File(path.join(projectPath, filename));
      if (await source.exists()) {
        await source.copy(path.join(packageDirectory.path, filename));
      }
    }

    final crashLog = File(path.join(projectPath, 'release_manager_crash.log'));
    if (await crashLog.exists()) {
      await crashLog.copy(
        path.join(packageDirectory.path, 'release_manager_crash.log'),
      );
    }

    Future<void> captureFlutterInfo(
      List<String> arguments,
      String filename,
    ) async {
      try {
        final result = await Process.run(
          'flutter',
          arguments,
          workingDirectory: projectPath,
          runInShell: true,
        );
        await File(path.join(packageDirectory.path, filename)).writeAsString(
          '${result.stdout}\n${result.stderr}',
          flush: true,
        );
      } catch (error) {
        await File(path.join(packageDirectory.path, filename)).writeAsString(
          'Nepodarilo sa získať údaje: $error',
          flush: true,
        );
      }
    }

    await captureFlutterInfo(<String>['--version'], 'flutter_version.txt');
    await captureFlutterInfo(<String>['doctor', '-v'], 'flutter_doctor.txt');

    final zipFile = File(path.join(diagnosticsRoot.path, 'Diagnostics_$stamp.zip'));
    final source = packageDirectory.path.replaceAll("'", "''");
    final destination = zipFile.path.replaceAll("'", "''");
    final result = await Process.run(
      'powershell.exe',
      <String>[
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        "Compress-Archive -LiteralPath '$source' -DestinationPath '$destination' -CompressionLevel Optimal -Force",
      ],
      runInShell: false,
    );
    if (result.exitCode != 0 || !await zipFile.exists()) {
      throw StateError(
        'Diagnostický ZIP sa nepodarilo vytvoriť: ${result.stderr}',
      );
    }
    return zipFile;
  }

  Future<void> _openDirectory(String directoryPath) async {
    await Process.start(
      'explorer.exe',
      <String>[directoryPath],
      runInShell: false,
    );
  }

  Future<void> _openAndExtractZip({bool startBuildAfterExtract = false}) async {
    if (_zipExtracting) return;

    final result = await FilePicker.pickFiles(
      dialogTitle: 'Vyber ZIP súbor na rozbalenie',
      type: FileType.custom,
      allowedExtensions: const <String>['zip'],
      allowMultiple: false,
    );
    final zipPath = result?.files.single.path;
    if (zipPath == null) {
      _addLog('Výber ZIP súboru bol zrušený.');
      return;
    }

    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      _showError('Vybraný ZIP súbor neexistuje.');
      return;
    }

    final parentDirectory = zipFile.parent;
    final baseName = path.basenameWithoutExtension(zipFile.path);
    var targetDirectory = Directory(path.join(parentDirectory.path, baseName));
    var suffix = 2;
    while (await targetDirectory.exists()) {
      targetDirectory = Directory(
        path.join(parentDirectory.path, '$baseName ($suffix)'),
      );
      suffix++;
    }

    if (!mounted) return;
    setState(() => _zipExtracting = true);
    _addLog('Rozbaľujem ZIP: ${zipFile.path}');
    _addLog('Cieľový priečinok: ${targetDirectory.path}');

    try {
      await targetDirectory.create(recursive: true);
      final source = _powershellLiteral(zipFile.path);
      final destination = _powershellLiteral(targetDirectory.path);
      final processResult = await Process.run(
        'powershell.exe',
        <String>[
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          "Expand-Archive -LiteralPath '$source' -DestinationPath '$destination' -Force",
        ],
        runInShell: false,
      );

      if (processResult.exitCode != 0) {
        throw StateError(
          'PowerShell vrátil kód ${processResult.exitCode}: '
          '${processResult.stderr}',
        );
      }

      final extractedItems = await targetDirectory.list().toList();
      if (extractedItems.length == 1 && extractedItems.single is Directory) {
        final nestedRoot = extractedItems.single as Directory;
        final nestedItems = await nestedRoot.list().toList();
        for (final item in nestedItems) {
          final destinationPath = path.join(
            targetDirectory.path,
            path.basename(item.path),
          );
          await item.rename(destinationPath);
        }
        await nestedRoot.delete();
        _addLog(
          'Odstránená nadbytočná koreňová úroveň ZIP: '
          '${path.basename(nestedRoot.path)}',
        );
      }

      _addLog('ZIP bol úspešne rozbalený: ${targetDirectory.path}');

      // Release Wizard: rozbalený Flutter projekt sa automaticky použije
      // ako zdroj pre krok Build Release Managera. Ručný výber adresára
      // zostáva dostupný cez tlačidlo VYBRAŤ PROJEKT.
      final extractedPubspec = File(path.join(targetDirectory.path, 'pubspec.yaml'));
      final extractedWindowsDirectory = Directory(path.join(targetDirectory.path, 'windows'));
      if (!await extractedPubspec.exists() || !await extractedWindowsDirectory.exists()) {
        throw const FileSystemException(
          'Rozbalený ZIP nie je platný Flutter Windows projekt. '
          'V koreňovom priečinku musí byť pubspec.yaml a priečinok windows.',
        );
      }

      final pubspecText = await extractedPubspec.readAsString();
      final versionMatch = RegExp(
        r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
        multiLine: true,
      ).firstMatch(pubspecText);

      if (!mounted) return;
      setState(() {
        _managerProjectPath = targetDirectory.path;
        _managerReleaseDirectoryPath = null;
        _managerPackagePath = null;
        _managerBuildSucceeded = false;
        _managerPublished = false;
        _managerApplicationLaunched = false;
        if (versionMatch != null) {
          _managerVersionController.text = versionMatch.group(1)!;
          _managerBuildController.text = versionMatch.group(2)!;
        }
      });
      _addLog(
        'Rozbalený projekt bol automaticky načítaný pre Build Release Managera: '
        '${targetDirectory.path}',
      );
      if (versionMatch != null) {
        _addLog(
          'Načítaná verzia rozbaleného projektu: '
          '${versionMatch.group(1)} Build ${versionMatch.group(2)}',
        );
      }
      if (startBuildAfterExtract) {
        // Rozbalenie je v tejto chvíli už hotové. Stav ZIP kroku preto
        // ukončíme ešte pred spustením dlhého Windows buildu, aby sa
        // indikátor netočil počas nasledujúceho kroku.
        if (mounted) {
          setState(() => _zipExtracting = false);
        }
        _addLog('ZIP krok dokončený. Quick Build pokračuje Windows buildom.');
        _addLog('Quick Build: projekt je pripravený, automaticky spúšťam kompletný Windows build.');
        await _buildReleaseManagerWindows();
      } else {
        _showSuccess(
          'ZIP bol úspešne rozbalený a projekt bol automaticky nastavený '
          'pre Build Release Managera.\n\n${targetDirectory.path}',
        );
      }
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Rozbalenie ZIP súboru',
      );
      if (await targetDirectory.exists()) {
        try {
          await targetDirectory.delete(recursive: true);
        } catch (_) {
          // Neúplný priečinok sa nemusí dať odstrániť, ak ho blokuje iný proces.
        }
      }
      _addLog('Rozbalenie ZIP zlyhalo: $error');
      if (mounted) {
        _showError('ZIP sa nepodarilo rozbaliť: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _zipExtracting = false);
      }
    }
  }


  Future<void> _openAndExtractAndroidZip() async {
    if (_zipExtracting) return;

    final result = await FilePicker.pickFiles(
      dialogTitle: 'Vyber ZIP projektu STAVBY PRO',
      type: FileType.custom,
      allowedExtensions: const <String>['zip'],
      allowMultiple: false,
    );
    final zipPath = result?.files.single.path;
    if (zipPath == null) {
      _addLog('Výber Android ZIP súboru bol zrušený.');
      return;
    }

    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      _showError('Vybraný ZIP súbor neexistuje.');
      return;
    }

    final parentDirectory = zipFile.parent;
    final baseName = path.basenameWithoutExtension(zipFile.path);
    var targetDirectory = Directory(path.join(parentDirectory.path, baseName));
    var suffix = 2;
    while (await targetDirectory.exists()) {
      targetDirectory = Directory(path.join(parentDirectory.path, '$baseName ($suffix)'));
      suffix++;
    }

    if (!mounted) return;
    setState(() {
      _zipExtracting = true;
      _androidZipExtracted = false;
      _androidExtractedProjectPath = null;
      _completedApkBuildSteps.clear();
    });
    _addLog('Rozbaľujem Android projekt ZIP: ${zipFile.path}');
    _addLog('Cieľový priečinok: ${targetDirectory.path}');

    try {
      await targetDirectory.create(recursive: true);
      final source = _powershellLiteral(zipFile.path);
      final destination = _powershellLiteral(targetDirectory.path);
      final processResult = await Process.run(
        'powershell.exe',
        <String>[
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          "Expand-Archive -LiteralPath '$source' -DestinationPath '$destination' -Force",
        ],
        runInShell: false,
      );
      if (processResult.exitCode != 0) {
        throw StateError('PowerShell vrátil kód ${processResult.exitCode}: ${processResult.stderr}');
      }

      final extractedItems = await targetDirectory.list().toList();
      if (extractedItems.length == 1 && extractedItems.single is Directory) {
        final nestedRoot = extractedItems.single as Directory;
        final nestedItems = await nestedRoot.list().toList();
        for (final item in nestedItems) {
          await item.rename(path.join(targetDirectory.path, path.basename(item.path)));
        }
        await nestedRoot.delete();
        _addLog('Odstránená nadbytočná koreňová úroveň ZIP: ${path.basename(nestedRoot.path)}');
      }

      if (!await File(path.join(targetDirectory.path, 'pubspec.yaml')).exists()) {
        throw const FileSystemException('Rozbalený ZIP neobsahuje pubspec.yaml v koreňovom priečinku.');
      }

      if (!mounted) return;
      setState(() {
        _androidZipExtracted = true;
        _androidExtractedProjectPath = targetDirectory.path;
      });
      _addLog('Android projekt ZIP bol úspešne rozbalený: ${targetDirectory.path}');
      await _openProjectPath(targetDirectory.path);
      if (mounted) {
        _showSuccess('ZIP bol rozbalený a projekt STAVBY PRO bol načítaný.');
      }
    } catch (error, stackTrace) {
      await _writeCrashLog(error, stackTrace, step: 'Rozbalenie Android ZIP súboru');
      if (await targetDirectory.exists()) {
        try { await targetDirectory.delete(recursive: true); } catch (_) {}
      }
      _addLog('Rozbalenie Android ZIP zlyhalo: $error');
      if (mounted) _showError('Android ZIP sa nepodarilo rozbaliť: $error');
    } finally {
      if (mounted) setState(() => _zipExtracting = false);
    }
  }

  Future<void> _openExistingWindowsProject() async {
    if (_busy || _zipExtracting) return;

    String? selectedPath;
    try {
      selectedPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Vyber existujúci Windows DEV projekt STAVBY PRO',
        lockParentWindow: true,
      );
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Otvorenie existujúceho Windows DEV projektu',
      );
      if (mounted) _showError('Výber Windows projektu zlyhal: $error');
      return;
    }

    if (selectedPath == null || selectedPath.trim().isEmpty) {
      _addLog('Výber existujúceho Windows projektu bol zrušený.');
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final pubspec = File(path.join(selectedPath, 'pubspec.yaml'));
    final windowsDirectory = Directory(path.join(selectedPath, 'windows'));
    if (!await pubspec.exists() || !await windowsDirectory.exists()) {
      _showError(
        'Vybraný priečinok nie je platný Flutter Windows projekt STAVBY PRO. '
        'Musí obsahovať pubspec.yaml a priečinok windows.',
      );
      return;
    }

    setState(() {
      _windowsZipExtracted = true;
      _windowsExtractedProjectPath = selectedPath;
      _windowsWorkspace.completedBuildSteps.clear();
      _windowsBuiltExePath = null;
      _windowsExportedPath = null;
      _windowsLaunchStatus = 'EXE ešte nebolo spustené.';
    });
    _addLog('Existujúci Windows DEV projekt vybraný: $selectedPath');

    await _openProjectPath(selectedPath);
    if (mounted) {
      _showSuccess('Existujúci Windows DEV projekt bol úspešne načítaný.');
    }
  }

  Future<void> _openAndExtractWindowsZip() async {
    if (_zipExtracting) return;

    final result = await FilePicker.pickFiles(
      dialogTitle: 'Vyber ZIP projektu STAVBY PRO',
      type: FileType.custom,
      allowedExtensions: const <String>['zip'],
      allowMultiple: false,
    );
    final zipPath = result?.files.single.path;
    if (zipPath == null) {
      _addLog('Výber Windows ZIP súboru bol zrušený.');
      return;
    }

    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      _showError('Vybraný ZIP súbor neexistuje.');
      return;
    }

    final parentDirectory = zipFile.parent;
    final baseName = path.basenameWithoutExtension(zipFile.path);
    var targetDirectory = Directory(path.join(parentDirectory.path, baseName));
    var suffix = 2;
    while (await targetDirectory.exists()) {
      targetDirectory = Directory(path.join(parentDirectory.path, '$baseName ($suffix)'));
      suffix++;
    }

    if (!mounted) return;
    setState(() {
      _zipExtracting = true;
      _windowsZipExtracted = false;
      _windowsExtractedProjectPath = null;
      _windowsWorkspace.completedBuildSteps.clear();
      _windowsBuiltExePath = null;
      _windowsExportedPath = null;
    });
    _addLog('Rozbaľujem Windows DEV projekt ZIP: ${zipFile.path}');
    _addLog('Cieľový priečinok: ${targetDirectory.path}');

    try {
      await targetDirectory.create(recursive: true);
      final source = _powershellLiteral(zipFile.path);
      final destination = _powershellLiteral(targetDirectory.path);
      final processResult = await Process.run(
        'powershell.exe',
        <String>[
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          "Expand-Archive -LiteralPath '$source' -DestinationPath '$destination' -Force",
        ],
        runInShell: false,
      );
      if (processResult.exitCode != 0) {
        throw StateError('PowerShell vrátil kód ${processResult.exitCode}: ${processResult.stderr}');
      }

      final extractedItems = await targetDirectory.list().toList();
      if (extractedItems.length == 1 && extractedItems.single is Directory) {
        final nestedRoot = extractedItems.single as Directory;
        final nestedItems = await nestedRoot.list().toList();
        for (final item in nestedItems) {
          await item.rename(path.join(targetDirectory.path, path.basename(item.path)));
        }
        await nestedRoot.delete();
        _addLog('Odstránená nadbytočná koreňová úroveň ZIP: ${path.basename(nestedRoot.path)}');
      }

      if (!await File(path.join(targetDirectory.path, 'pubspec.yaml')).exists()) {
        throw const FileSystemException('Rozbalený ZIP neobsahuje pubspec.yaml v koreňovom priečinku.');
      }

      if (!mounted) return;
      setState(() {
        _windowsZipExtracted = true;
        _windowsExtractedProjectPath = targetDirectory.path;
      });
      _addLog('Windows DEV projekt ZIP bol úspešne rozbalený: ${targetDirectory.path}');
      await _openProjectPath(targetDirectory.path);
      if (mounted) {
        _showSuccess('ZIP bol rozbalený a projekt STAVBY PRO bol načítaný.');
      }
    } catch (error, stackTrace) {
      await _writeCrashLog(error, stackTrace, step: 'Rozbalenie Windows ZIP súboru');
      if (await targetDirectory.exists()) {
        try { await targetDirectory.delete(recursive: true); } catch (_) {}
      }
      _addLog('Rozbalenie Windows ZIP zlyhalo: $error');
      if (mounted) _showError('Windows ZIP sa nepodarilo rozbaliť: $error');
    } finally {
      if (mounted) setState(() => _zipExtracting = false);
    }
  }



  ({int errors, int warnings, String firstIssue, String? filePath, int? line})
      _summarizeBuildFailure(List<String> output) {
    var errors = 0;
    var warnings = 0;
    String firstIssue = 'Presná príčina je uvedená v diagnostickom reporte.';
    String? filePath;
    int? line;
    final locationPattern = RegExp(r'([A-Za-z]:\\[^:\r\n]+|(?:lib|test|windows|android)[\\/][^:\r\n]+):(\d+):(\d+)');
    for (final raw in output) {
      final text = raw.trim();
      final lower = text.toLowerCase();
      if (lower.contains(' error - ') || lower.startsWith('error -') || lower.startsWith('chyba:')) {
        errors++;
        if (firstIssue.startsWith('Presná príčina')) {
          firstIssue = text.replaceFirst(RegExp(r'^CHYBA:\s*'), '');
        }
      } else if (lower.contains(' warning - ') || lower.startsWith('warning -')) {
        warnings++;
      }
      if (filePath == null) {
        final match = locationPattern.firstMatch(text);
        if (match != null) {
          filePath = match.group(1)?.replaceAll('\\', Platform.pathSeparator).replaceAll('/', Platform.pathSeparator);
          line = int.tryParse(match.group(2) ?? '');
        }
      }
    }
    return (errors: errors, warnings: warnings, firstIssue: firstIssue, filePath: filePath, line: line);
  }

  bool _looksLikeDependencyFailure(List<String> output) {
    final text = output.join('\n').toLowerCase();
    return text.contains("target of uri doesn't exist") ||
        text.contains('could not find package') ||
        text.contains("undefined name 'filepicker'") ||
        text.contains("undefined class 'packageinfo'") ||
        text.contains('package_config.json') ||
        text.contains('default plugin') ||
        text.contains('not found in pubspec');
  }

  Future<void> _openProblemFile({
    required String projectPath,
    required String? filePath,
  }) async {
    if (filePath == null || filePath.trim().isEmpty) {
      _showError('V diagnostike sa nepodarilo nájsť cestu k problémovému súboru.');
      return;
    }
    final resolved = path.isAbsolute(filePath)
        ? filePath
        : path.normalize(path.join(projectPath, filePath));
    final file = File(resolved);
    if (!await file.exists()) {
      _showError('Problémový súbor neexistuje: $resolved');
      return;
    }
    await Process.start('explorer.exe', <String>['/select,', resolved], runInShell: false);
  }

  Future<List<String>> _missingCriticalPackageFiles(String projectPath) async {
    final configFile = File(path.join(projectPath, '.dart_tool', 'package_config.json'));
    if (!await configFile.exists()) {
      return <String>['.dart_tool/package_config.json'];
    }
    try {
      final decoded = jsonDecode(await configFile.readAsString());
      if (decoded is! Map<String, dynamic>) return <String>['neplatný package_config.json'];
      final packages = decoded['packages'];
      if (packages is! List) return <String>['neplatný zoznam packages'];
      const expected = <String, String>{
        'file_picker': 'file_picker.dart',
        'package_info_plus': 'package_info_plus.dart',
        'printing': 'printing.dart',
        'geolocator_windows': 'geolocator_windows.dart',
        'image_picker_windows': 'image_picker_windows.dart',
      };
      final missing = <String>[];
      for (final entry in packages) {
        if (entry is! Map) continue;
        final name = entry['name']?.toString();
        if (name == null || !expected.containsKey(name)) continue;
        final rootRaw = entry['rootUri']?.toString() ?? '';
        final packageRaw = entry['packageUri']?.toString() ?? 'lib/';
        if (rootRaw.isEmpty) {
          missing.add('$name: chýba rootUri');
          continue;
        }
        final rootUri = Uri.parse(rootRaw);
        final rootPath = rootUri.scheme == 'file'
            ? rootUri.toFilePath(windows: Platform.isWindows)
            : path.normalize(path.join(projectPath, rootRaw));
        final packagePath = Uri.parse(packageRaw).path.replaceAll('/', Platform.pathSeparator);
        final entryFile = File(path.join(rootPath, packagePath, expected[name]!));
        if (!await entryFile.exists()) {
          missing.add('$name: ${entryFile.path}');
        }
      }
      for (final name in expected.keys) {
        final present = packages.any((entry) => entry is Map && entry['name']?.toString() == name);
        if (!present) missing.add('$name: nie je v package_config.json');
      }
      return missing;
    } catch (error) {
      return <String>['package_config.json sa nepodarilo načítať: $error'];
    }
  }

  Future<bool> _repairWorkspaceDependencies(String projectPath) async {
    _addLog('=== ZAČÍNA HĹBKOVÁ OPRAVA ZÁVISLOSTÍ ===');
    try {
      for (final relative in <String>['.dart_tool', '.flutter-plugins', '.flutter-plugins-dependencies']) {
        final entityPath = path.join(projectPath, relative);
        final type = FileSystemEntity.typeSync(entityPath);
        if (type == FileSystemEntityType.directory) {
          await Directory(entityPath).delete(recursive: true);
          _addLog('Odstránený priečinok: $relative');
        } else if (type == FileSystemEntityType.file) {
          await File(entityPath).delete();
          _addLog('Odstránený súbor: $relative');
        }
      }

      _addLog('▶ dart pub cache repair');
      final cacheRepair = await Process.run(
        'dart',
        <String>['pub', 'cache', 'repair'],
        workingDirectory: projectPath,
        runInShell: true,
      );
      _addLog('${cacheRepair.stdout}');
      if (cacheRepair.stderr.toString().trim().isNotEmpty) {
        _addLog('CHYBA: ${cacheRepair.stderr}');
      }
      if (cacheRepair.exitCode != 0) {
        throw StateError('dart pub cache repair zlyhal s kódom ${cacheRepair.exitCode}.');
      }

      final clean = await Process.run('flutter', <String>['clean'], workingDirectory: projectPath, runInShell: true);
      _addLog('${clean.stdout}');
      if (clean.stderr.toString().trim().isNotEmpty) _addLog('CHYBA: ${clean.stderr}');

      final get = await Process.run('flutter', <String>['pub', 'get'], workingDirectory: projectPath, runInShell: true);
      _addLog('${get.stdout}');
      if (get.stderr.toString().trim().isNotEmpty) _addLog('CHYBA: ${get.stderr}');
      if (get.exitCode != 0) {
        throw StateError('flutter pub get zlyhal s kódom ${get.exitCode}.');
      }

      final missing = await _missingCriticalPackageFiles(projectPath);
      if (missing.isNotEmpty) {
        throw StateError('Po oprave stále chýbajú súbory balíkov:\n${missing.join('\n')}');
      }
      _addLog('✔ Pub cache, package_config.json a kritické balíky boli overené.');
      return true;
    } catch (error, stackTrace) {
      await _writeCrashLog(error, stackTrace, step: 'Hĺbková oprava závislostí', projectPath: projectPath);
      _addLog('Oprava závislostí zlyhala: $error');
      if (mounted) _showError('Závislosti sa nepodarilo opraviť: $error');
      return false;
    }
  }

  Future<File> _writeSuccessfulBuildReport({
    required String projectPath,
    required DateTime startedAt,
  }) async {
    final pubspec = File(path.join(projectPath, 'pubspec.yaml'));
    var identity = 'neznáma verzia';
    if (await pubspec.exists()) {
      final text = await pubspec.readAsString();
      identity = RegExp(r'^version:\s*([^\s]+)', multiLine: true).firstMatch(text)?.group(1) ?? identity;
    }
    final report = StringBuffer()
      ..writeln('STAVBY PRO – BUILD REPORT')
      ..writeln('========================================')
      ..writeln('Projekt: ${path.basename(projectPath)}')
      ..writeln('Cesta: $projectPath')
      ..writeln('Verzia: $identity')
      ..writeln('Release Manager: ${ReleaseManagerVersion.label}')
      ..writeln('Začiatok: ${startedAt.toIso8601String()}')
      ..writeln('Koniec: ${DateTime.now().toIso8601String()}')
      ..writeln('Trvanie: ${DateTime.now().difference(startedAt).inSeconds} s')
      ..writeln()
      ..writeln('✔ flutter clean')
      ..writeln('✔ flutter pub get')
      ..writeln('✔ flutter analyze')
      ..writeln('✔ flutter test')
      ..writeln('✔ flutter build windows --release');
    final file = File(path.join(projectPath, 'BUILD_REPORT_${_diagnosticTimeStamp(DateTime.now())}.txt'));
    await file.writeAsString(report.toString(), flush: true);
    _addLog('Build report bol vytvorený: ${file.path}');
    return file;
  }

  Future<void> _showBuildFailureDialog({
    required String projectName,
    required String projectPath,
    required String label,
    required List<String> arguments,
    required List<String> output,
    int? exitCode,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final summary = _summarizeBuildFailure(output);
    final dependencyFailure = _looksLikeDependencyFailure(output);
    final report = _buildDiagnosticReport(
      projectName: projectName,
      projectPath: projectPath,
      label: label,
      arguments: arguments,
      output: output,
      exitCode: exitCode,
      error: error,
      stackTrace: stackTrace,
    );

    File? reportFile;
    Object? reportSaveError;
    try {
      reportFile = await _saveDiagnosticReport(
        projectPath: projectPath,
        report: report,
      );
      _addLog(
        'Diagnostický report bol automaticky uložený: ${reportFile.path}',
      );
    } catch (saveError, saveStackTrace) {
      reportSaveError = saveError;
      _addLog('Diagnostický report sa nepodarilo automaticky uložiť: $saveError');
      await _writeCrashLog(
        saveError,
        saveStackTrace,
        step: 'Uloženie diagnostického reportu',
        projectPath: projectPath,
      );
    }

    if (!mounted) {
      _addLog(
        'Diagnostické okno sa neotvorilo: aplikácia už nie je pripojená k UI.',
      );
      return;
    }

    // Najprv uvoľni busy vrstvu. Diagnostika sa musí otvoriť nad celou
    // aplikáciou až po dokončení prekreslenia neúspešného build kroku.
    setState(() {
      _busy = false;
      _activeCommand = null;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final rootContext = appNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) {
      _addLog('Globálny navigátor nie je pripravený na diagnostické okno.');
      _showError('Diagnostický report bol vytvorený, ale okno sa nepodarilo otvoriť.');
      return;
    }

    final savedPathText = reportFile == null
        ? 'Automatické uloženie reportu zlyhalo. Detail chyby je napriek tomu '
            'zobrazený a môžeš ho uložiť tlačidlom ULOŽIŤ AKO.'
        : 'Report bol automaticky uložený do:\n${reportFile.path}';

    try {
      await showDialog<void>(
        context: rootContext,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.error_outline, size: 42),
          title: const Text('BUILD ZLYHAL – DIAGNOSTIKA'),
          content: SizedBox(
            width: (MediaQuery.sizeOf(dialogContext).width - 80).clamp(520.0, 900.0),
            height: (MediaQuery.sizeOf(dialogContext).height - 180).clamp(360.0, 620.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext).colorScheme.errorContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('Chyby: ${summary.errors}  •  Upozornenia: ${summary.warnings}'),
                      const SizedBox(height: 6),
                      Text(summary.firstIssue, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(savedPathText),
                if (reportSaveError != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'Chyba uloženia reportu: $reportSaveError',
                    style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(dialogContext).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        report,
                        style: const TextStyle(
                          fontFamily: 'Consolas',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            if (dependencyFailure)
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  final repaired = await _repairWorkspaceDependencies(projectPath);
                  if (!repaired || !mounted) return;
                  setState(() {
                    _oneClickBuildRunning = false;
                    _oneClickBuildResumeIndex = 2;
                    _oneClickBuildFailedLabel = 'Flutter analyze';
                  });
                  await _runOneClickBuild();
                },
                icon: const Icon(Icons.build_circle_outlined),
                label: const Text('OPRAVIŤ ZÁVISLOSTI'),
              ),
            if (summary.filePath != null)
              TextButton.icon(
                onPressed: () => _openProblemFile(projectPath: projectPath, filePath: summary.filePath),
                icon: const Icon(Icons.description_outlined),
                label: Text(summary.line == null ? 'OTVORIŤ SÚBOR' : 'OTVORIŤ SÚBOR • RIADOK ${summary.line}'),
              ),
            if (reportFile != null)
              TextButton.icon(
                onPressed: () => _openDirectory(reportFile!.parent.path),
                icon: const Icon(Icons.folder_open),
                label: const Text('OTVORIŤ PRIEČINOK'),
              ),
            TextButton.icon(
              onPressed: () => _saveDiagnosticReportAs(report),
              icon: const Icon(Icons.save_alt),
              label: const Text('ULOŽIŤ AKO'),
            ),
            TextButton.icon(
              onPressed: () async {
                try {
                  final zipFile = await _exportDiagnosticPackage(
                    projectPath: projectPath,
                    report: report,
                  );
                  _addLog('Diagnostický balík bol vytvorený: ${zipFile.path}');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Diagnostický ZIP bol vytvorený: ${zipFile.path}',
                        ),
                      ),
                    );
                  }
                  await _openDirectory(zipFile.parent.path);
                } catch (exportError) {
                  if (mounted) {
                    _showError(
                      'Diagnostický ZIP sa nepodarilo vytvoriť: $exportError',
                    );
                  }
                }
              },
              icon: const Icon(Icons.archive_outlined),
              label: const Text('EXPORT ZIP'),
            ),
            if (_lastProjectSnapshot != null)
              TextButton.icon(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _restoreLastProjectSnapshot();
                },
                icon: const Icon(Icons.restore_rounded),
                label: const Text('OBNOVIŤ SNAPSHOT'),
              ),
            FilledButton.icon(
              onPressed: () => _copyDiagnosticReport(report),
              icon: const Icon(Icons.copy_all),
              label: const Text('KOPÍROVAŤ PRE CHATGPT'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ZAVRIEŤ'),
            ),
          ],
        ),
      );
      _addLog('Diagnostické okno bolo zatvorené.');
    } catch (dialogError, dialogStackTrace) {
      await _writeCrashLog(
        dialogError,
        dialogStackTrace,
        step: 'Zobrazenie diagnostického okna',
        projectPath: projectPath,
      );
      _addLog('Diagnostické okno sa nepodarilo otvoriť: $dialogError');
      if (mounted) {
        _showError(
          'Diagnostické okno sa nepodarilo otvoriť. Report môžeš skopírovať '
          'zo živého terminálu. Chyba: $dialogError',
        );
      }
    }
  }

  Future<bool> _runManagerFlutterCommand(
    List<String> arguments, {
    required String label,
  }) async {
    final projectPath = _managerProjectPath;
    if (projectPath == null) {
      _showError('Najprv vyber zdrojový priečinok Release Managera.');
      return false;
    }

    if (mounted) {
      setState(() => _activeCommand = label);
    }
    final isApkReleaseBuild = label == 'Release APK build';
    if (isApkReleaseBuild) {
      _startFlutterStepProgress(label);
    }
    _addLog('▶ flutter ${arguments.join(' ')}');
    final commandOutput = <String>[];

    try {
      final process = await Process.start(
        'flutter',
        arguments,
        workingDirectory: projectPath,
        runInShell: true,
      );

      final stdoutDone = process.stdout
          .transform(systemEncoding.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            commandOutput.add(line);
            _addLog(line);
          })
          .asFuture<void>();
      final stderrDone = process.stderr
          .transform(systemEncoding.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            commandOutput.add('CHYBA: $line');
            _addLog('CHYBA: $line');
          })
          .asFuture<void>();

      final exitCode = await process.exitCode;
      await Future.wait<void>(<Future<void>>[stdoutDone, stderrDone]);

      final analyzeAccepted = label == 'Flutter analyze'
          ? _acceptAnalyzeResult(exitCode: exitCode, output: commandOutput)
          : exitCode == 0;
      if (analyzeAccepted) {
        if (isApkReleaseBuild) {
          _finishFlutterStepProgress(success: true);
        }
        if (label == 'Flutter analyze' && exitCode != 0) {
          _addLog('⚠ Flutter analyze obsahuje iba upozornenia. Professional Mode pokračuje v builde.');
        } else {
          _addLog('✔ $label bol úspešne dokončený.');
        }
        return true;
      }

      if (isApkReleaseBuild) {
        _finishFlutterStepProgress(success: false);
      }
      _addLog('✖ $label zlyhal. Návratový kód: $exitCode.');
      await _showBuildFailureDialog(
        projectName: 'STAVBY PRO Release Manager',
        projectPath: projectPath,
        label: label,
        arguments: arguments,
        output: commandOutput,
        exitCode: exitCode,
      );
      return false;
    } on ProcessException catch (error, stackTrace) {
      if (isApkReleaseBuild) {
        _finishFlutterStepProgress(success: false);
      }
      commandOutput.add('ProcessException: ${error.message}');
      _addLog('CHYBA: Flutter sa nepodarilo spustiť: ${error.message}');
      await _showBuildFailureDialog(
        projectName: 'STAVBY PRO Release Manager',
        projectPath: projectPath,
        label: label,
        arguments: arguments,
        output: commandOutput,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: label,
        projectPath: projectPath,
      );
      commandOutput.add('CHYBA: $error');
      _addLog('CHYBA: $label zlyhal: $error');
      await _showBuildFailureDialog(
        projectName: 'STAVBY PRO Release Manager',
        projectPath: projectPath,
        label: label,
        arguments: arguments,
        output: commandOutput,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _buildReleaseManagerWindows() async {
    if (_managerBuildRunning) return;
    final projectPath = _managerProjectPath;
    if (projectPath == null) {
      _showError('Najprv vyber zdrojový priečinok Release Managera.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Spustiť kompletný Windows build?'),
        content: Text(
          'Projekt:\n$projectPath\n\n'
          'Postupne sa vykoná:\n'
          '• flutter clean\n'
          '• flutter pub get\n'
          '• flutter analyze\n'
          '• flutter test\n'
          '• flutter build windows --release',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ZRUŠIŤ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('SPUSTIŤ BUILD'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _managerBuildRunning = true;
      _managerBuildSucceeded = false;
      _managerReleaseDirectoryPath = null;
      _managerPackagePath = null;
      _activeCommand = 'Príprava buildu Release Managera';
    });

    _addLog('=== ZAČÍNA KOMPLETNÝ WINDOWS BUILD RELEASE MANAGERA ===');

    final steps = <({List<String> arguments, String label})>[
      (arguments: <String>['clean'], label: 'Flutter clean'),
      (arguments: <String>['pub', 'get'], label: 'Flutter pub get'),
      (arguments: <String>['analyze'], label: 'Flutter analyze'),
      (arguments: <String>['test'], label: 'Flutter test'),
      (
        arguments: <String>['build', 'windows', '--release'],
        label: 'Windows Release build',
      ),
    ];

    try {
      for (final step in steps) {
        final success = await _runManagerFlutterCommand(
          step.arguments,
          label: step.label,
        );
        if (!success) {
          _addLog('=== WINDOWS BUILD ZASTAVENÝ PRE CHYBU ===');
          return;
        }
      }

      final releasePath = path.join(
        projectPath,
        'build',
        'windows',
        'x64',
        'runner',
        'Release',
      );
      final releaseDirectory = Directory(releasePath);
      if (!await releaseDirectory.exists()) {
        throw StateError(
          'Build skončil bez chyby, ale Release priečinok nebol nájdený: $releasePath',
        );
      }

      if (!mounted) return;
      setState(() {
        _managerBuildSucceeded = true;
        _managerReleaseDirectoryPath = releasePath;
      });
      _addLog('=== WINDOWS BUILD RELEASE MANAGERA BOL ÚSPEŠNÝ ===');
      _addLog('Release priečinok: $releasePath');
      _showSuccess(
        'Release Manager bol úspešne skompilovaný. Release priečinok je automaticky pripravený na publikovanie.',
      );
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Kompletný Windows build Release Managera',
        projectPath: projectPath,
      );
      _addLog('CHYBA buildu Release Managera: $error');
      if (mounted) {
        _showError('Build Release Managera zlyhal: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _managerBuildRunning = false;
          _activeCommand = null;
        });
      }
    }
  }

  Future<void> _openManagerReleaseDirectory() async {
    final releasePath = _managerReleaseDirectoryPath;
    if (releasePath == null || !await Directory(releasePath).exists()) {
      _showError('Release priečinok zatiaľ neexistuje.');
      return;
    }
    try {
      await Process.start(
        'explorer.exe',
        <String>[releasePath],
        runInShell: false,
      );
    } catch (error) {
      _showError('Release priečinok sa nepodarilo otvoriť: $error');
    }
  }

  Future<void> _launchFinishedManagerApplication() async {
    final candidates = <File>[];
    final projectPath = _managerProjectPath;
    if (projectPath != null) {
      final directory = Directory(path.join(
        projectPath,
        'build',
        'windows',
        'x64',
        'runner',
        'Release',
      ));
      if (await directory.exists()) {
        candidates.addAll(
          directory
              .listSync(followLinks: false)
              .whereType<File>()
              .where((file) => file.path.toLowerCase().endsWith('.exe')),
        );
      }
    }
    final releasePath = _managerReleaseDirectoryPath;
    if (candidates.isEmpty && releasePath != null) {
      final directory = Directory(releasePath);
      if (await directory.exists()) {
        candidates.addAll(
          directory
              .listSync(recursive: true, followLinks: false)
              .whereType<File>()
              .where((file) => file.path.toLowerCase().endsWith('.exe')),
        );
      }
    }
    if (candidates.isEmpty) {
      _showError('Hotová aplikácia zatiaľ neexistuje. Najprv dokonči Windows build.');
      return;
    }
    candidates.sort((a, b) => a.path.length.compareTo(b.path.length));
    try {
      await Process.start(candidates.first.path, const <String>[], runInShell: false);
      if (mounted) {
        setState(() => _managerApplicationLaunched = true);
      }
      _addLog('Spustená hotová aplikácia: ${candidates.first.path}');
    } catch (error) {
      _showError('Hotovú aplikáciu sa nepodarilo spustiť: $error');
    }
  }

  Future<void> _selectManagerReleaseDirectory() async {
    _addLog('Otváram výber Release priečinka...');
    String? selectedPath;
    try {
      selectedPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Vyber priečinok build/windows/x64/runner/Release',
      );
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Výber Release priečinka',
      );
      if (mounted) {
        _showError('Výber priečinka zlyhal: $error');
      }
      return;
    }

    if (selectedPath == null) {
      _addLog('Výber Release priečinka bol zrušený.');
      return;
    }

    // Na Windows necháme natívny dialóg úplne ukončiť callback pred tým,
    // ako začneme pracovať so zvolenou cestou. Staršia verzia file_picker
    // mohla bezprostredne po potvrdení priečinka spôsobiť natívny pád.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    _addLog('Overujem vybraný Release priečinok: $selectedPath');
    try {
      final directory = Directory(selectedPath);
      if (!await directory.exists()) {
        _showError('Vybraný priečinok už neexistuje.');
        return;
      }

      var executableExists = false;
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.exe')) {
          executableExists = true;
          break;
        }
      }

      if (!executableExists) {
        _showError(
          'Vybraný priečinok neobsahuje Windows EXE súbor. '
          'Vyber priečinok runner/Release.',
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _managerReleaseDirectoryPath = selectedPath;
        _managerPackagePath = null;
      });
      _addLog('Vybraný Release priečinok: $selectedPath');
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Overenie Release priečinka',
        projectPath: selectedPath,
      );
      if (mounted) {
        _showError('Priečinok sa nepodarilo overiť: $error');
      }
    }
  }

  Future<File> _createManagerZip({
    required String releaseDirectoryPath,
    required String outputDirectoryPath,
    required String expectedName,
  }) async {
    final source = Directory(releaseDirectoryPath);
    if (!await source.exists()) {
      throw StateError('Release priečinok neexistuje.');
    }
    final outputDirectory = Directory(outputDirectoryPath);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }
    final output = File(path.join(outputDirectory.path, expectedName));
    if (await output.exists()) await output.delete();

    final escapedSource = source.path.replaceAll("'", "''");
    final escapedOutput = output.path.replaceAll("'", "''");
    final command = "Compress-Archive -Path '$escapedSource\\*' -DestinationPath '$escapedOutput' -CompressionLevel Optimal -Force";
    final result = await Process.run(
      'powershell.exe',
      <String>['-NoProfile', '-NonInteractive', '-Command', command],
      runInShell: false,
    );
    if (result.exitCode != 0 || !await output.exists()) {
      throw StateError(
        'Vytvorenie ZIP zlyhalo: ${result.stderr.toString().trim()}',
      );
    }
    return output;
  }

  Future<void> _exportManagerReleasePackage() async {
    if (_managerPublishing || _managerBuildRunning) return;

    final version = _managerVersionController.text.trim();
    final build = int.tryParse(_managerBuildController.text.trim());
    final releaseDirectoryPath = _managerReleaseDirectoryPath;

    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version) ||
        build == null ||
        build <= 0) {
      _showError('Zadaj platnú verziu vo formáte X.Y.Z a kladné číslo buildu.');
      return;
    }
    if (releaseDirectoryPath == null ||
        !await Directory(releaseDirectoryPath).exists()) {
      _showError('Najprv vyber priečinok build/windows/x64/runner/Release.');
      return;
    }

    var exportDirectoryPath = _managerUpdateDownloadDirectory?.trim();
    if (exportDirectoryPath == null || exportDirectoryPath.isEmpty) {
      await _chooseManagerUpdateDirectory();
      exportDirectoryPath = _managerUpdateDownloadDirectory?.trim();
    }
    if (exportDirectoryPath == null || exportDirectoryPath.isEmpty) {
      _showError('Najprv nastav predvolený priečinok pre Export Release.');
      return;
    }

    final expectedName =
        'STAVBY_PRO_RELEASE_MANAGER_${version}_BUILD_$build.zip';
    if (mounted) setState(() => _managerPublishing = true);
    _addLog('Exportujem Release Manager ZIP z: $releaseDirectoryPath');
    _addLog('Cieľový Export Release priečinok: $exportDirectoryPath');
    try {
      final packageFile = await _createManagerZip(
        releaseDirectoryPath: releaseDirectoryPath,
        outputDirectoryPath: exportDirectoryPath,
        expectedName: expectedName,
      );
      if (!mounted) return;
      setState(() => _managerPackagePath = packageFile.path);
      _addLog('Export Release bol úspešný: ${packageFile.path}');
      _showSuccess('Release ZIP vytvorený: ${packageFile.path}');
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Export Release Managera',
        projectPath: releaseDirectoryPath,
      );
      if (mounted) _showError('Export Release zlyhal: $error');
    } finally {
      if (mounted) setState(() => _managerPublishing = false);
    }
  }

  Future<void> _publishReleaseManager() async {
    if (_managerPublishing) return;
    if (!_githubConnected) {
      _showError('Najprv úspešne otestuj GitHub pripojenie. Použije sa rovnaký vlastník a token.');
      return;
    }
    final version = _managerVersionController.text.trim();
    final build = int.tryParse(_managerBuildController.text.trim());
    final releaseDirectoryPath = _managerReleaseDirectoryPath;
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version) || build == null || build <= 0) {
      _showError('Zadaj platnú verziu vo formáte X.Y.Z a kladné číslo buildu.');
      return;
    }
    if (releaseDirectoryPath == null || !await Directory(releaseDirectoryPath).exists()) {
      _showError('Vyber priečinok build/windows/x64/runner/Release.');
      return;
    }

    var exportDirectoryPath = _managerUpdateDownloadDirectory?.trim();
    if (exportDirectoryPath == null || exportDirectoryPath.isEmpty) {
      await _chooseManagerUpdateDirectory();
      exportDirectoryPath = _managerUpdateDownloadDirectory?.trim();
    }
    if (exportDirectoryPath == null || exportDirectoryPath.isEmpty) {
      _showError('Najprv nastav predvolený priečinok pre Export Release.');
      return;
    }

    final expectedName = 'STAVBY_PRO_RELEASE_MANAGER_${version}_BUILD_$build.zip';
    final tag = 'release-manager-v$version-build$build';
    final notes = _managerReleaseNotesController.text.trim();
    final body = notes.isEmpty
        ? 'STAVBY PRO Release Manager $version Build $build'
        : notes;
    final managerSettings = GitHubSettings(
      owner: _currentGitHubSettings.owner,
      repository: 'STAVBY_PRO_RELEASE_MANAGER',
      token: _currentGitHubSettings.token,
    );
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Publikovať Release Manager?'),
        content: Text(
          'Repozitár: ${managerSettings.owner}/${managerSettings.repository}\n'
          'Zdroj: $releaseDirectoryPath\n'
          'Tag: $tag\n'
          'ZIP: $expectedName\n\n'
          'Aplikácia automaticky vytvorí ZIP z obsahu Release priečinka, aktualizuje version.json, vytvorí GitHub Release a nahrá ZIP.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ZRUŠIŤ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('PUBLIKOVAŤ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _managerPublishing = true);
    _startGitHubOperation(
      'Publikujem Release Manager',
      'Vytváram ZIP z Windows Release priečinka...',
    );
    try {
      final packageFile = await _createManagerZip(
        releaseDirectoryPath: releaseDirectoryPath,
        outputDirectoryPath: exportDirectoryPath,
        expectedName: expectedName,
      );
      if (mounted) setState(() => _managerPackagePath = packageFile.path);
      _addLog('ZIP vytvorený: ${packageFile.path}');

      final downloadUrl =
          'https://github.com/${managerSettings.owner}/${managerSettings.repository}/releases/latest/download/$expectedName';
      final versionJson = const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'version': version,
        'build': build,
        'downloadUrl': downloadUrl,
        'releaseNotes': body,
      });
      _setGitHubOperationDetail('Aktualizujem version.json v repozitári Release Managera...');
      final versionResult = await _githubSettingsService.updateVersionJson(
        settings: managerSettings,
        jsonContent: '$versionJson\n',
      );
      if (!versionResult.success) throw StateError(versionResult.message);

      _setGitHubOperationDetail('Vytváram alebo kontrolujem GitHub Release...');
      final releaseResult = await _githubSettingsService.createRelease(
        settings: managerSettings,
        tagName: tag,
        releaseName: 'STAVBY PRO Release Manager $version Build $build',
        body: body,
      );
      if (!releaseResult.success && !releaseResult.alreadyExists) {
        throw StateError(releaseResult.message);
      }

      _setGitHubOperationDetail('Nahrávam ZIP balík na GitHub...');
      final uploadResult = await _githubSettingsService.uploadReleaseAsset(
        settings: managerSettings,
        tagName: tag,
        file: packageFile,
        assetName: expectedName,
        overwriteExisting: true,
        onProgress: _updateGitHubUploadProgress,
      );
      if (!uploadResult.success) throw StateError(uploadResult.message);

      final releaseUrl = releaseResult.releaseUrl ??
          'https://github.com/${managerSettings.owner}/${managerSettings.repository}/releases/tag/$tag';
      _finishGitHubOperation(
        success: true,
        detail: 'Release Manager $version Build $build bol úspešne publikovaný.',
      );
      if (mounted) {
        setState(() => _managerPublished = true);
      }
      _addLog('Release Manager $version Build $build bol publikovaný: $releaseUrl');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Release Manager publikovaný'),
          content: SelectableText(
            '✓ ZIP automaticky vytvorený\n'
            '✓ version.json aktualizovaný\n'
            '✓ GitHub Release pripravený\n'
            '✓ ZIP nahraný\n\n'
            'Verzia: $version\nBuild: $build\nSúbor: $expectedName\n\n$releaseUrl',
          ),
          actions: <Widget>[
            TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: releaseUrl)),
              icon: const Icon(Icons.copy),
              label: const Text('KOPÍROVAŤ ODKAZ'),
            ),
            FilledButton.icon(
              onPressed: () => _openExternalUrl(releaseUrl),
              icon: const Icon(Icons.open_in_new),
              label: const Text('OTVORIŤ RELEASE'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('HOTOVO'),
            ),
          ],
        ),
      );
    } catch (error, stackTrace) {
      await _writeCrashLog(error, stackTrace, step: 'Publikovanie Release Managera');
      _finishGitHubOperation(success: false, detail: 'Publikovanie zlyhalo: $error');
      _showError('Publikovanie Release Managera zlyhalo: $error');
      _addLog('CHYBA publikovania Release Managera: $error');
    } finally {
      if (mounted) setState(() => _managerPublishing = false);
    }
  }

  Future<void> _openExternalUrl(String url) async {
    try {
      await Process.start(
        'cmd.exe',
        <String>['/c', 'start', '', url],
        runInShell: true,
      );
    } catch (error) {
      _showError('Odkaz sa nepodarilo otvoriť: $error');
    }
  }

  Future<void> _clearGitHubSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Odstrániť GitHub pripojenie?'),
        content: const Text(
          'Odstráni sa uložený vlastník, repozitár aj šifrovaný token z tohto počítača.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ZRUŠIŤ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ODSTRÁNIŤ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _githubSettingsService.clear();
    if (!mounted) return;
    setState(() {
      _githubOwnerController.text = 'marekmoravansky42';
      _githubRepositoryController.text = 'stavby-pro-updates';
      _githubTokenController.clear();
      _githubConnected = false;
      _githubStatus = 'GitHub pripojenie bolo odstránené';
    });
    _addLog('Uložené GitHub pripojenie bolo odstránené.');
  }


  File get _startupCrashLogFile => File(path.join(
        File(Platform.resolvedExecutable).parent.path,
        'release_manager_crash.log',
      ));

  Future<void> _checkPreviousCrashLog() async {
    final logFile = _startupCrashLogFile;
    try {
      if (!await logFile.exists()) return;
      final stat = await logFile.stat();
      if (stat.size == 0 || !mounted) return;

      final action = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded),
          title: const Text('Zistená chyba pri predchádzajúcom spustení'),
          content: Text(
            'Release Manager našiel diagnostický log z predchádzajúceho '
            'spustenia.\n\nPosledná zmena logu: '
            '${stat.modified.toLocal()}\n\nChcete ho otvoriť?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('ignore'),
              child: const Text('Ignorovať'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('delete'),
              child: const Text('Odstrániť log'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop('open'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Otvoriť'),
            ),
          ],
        ),
      );

      if (action == 'open') {
        await Process.start('notepad.exe', [logFile.path]);
        _addLog('Diagnostický log bol otvorený: ${logFile.path}');
      } else if (action == 'delete') {
        await logFile.delete();
        _addLog('Diagnostický log bol odstránený.');
      } else {
        _addLog('Diagnostický log bol pri štarte ignorovaný.');
      }
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Kontrola diagnostického logu pri štarte',
      );
      _addLog('Kontrola diagnostického logu zlyhala: $error');
    }
  }



  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      _diagnostics.add(message);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_terminalScrollController.hasClients) return;
      _terminalScrollController.animateTo(
        _terminalScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }




  File? _historyFile() {
    final project = _project;
    if (project == null) return null;
    return File(path.join(project.projectPath, '.release_manager_history.json'));
  }

  Future<void> _loadReleaseHistory() async {
    final file = _historyFile();
    if (file == null || !await file.exists()) {
      if (mounted) setState(() => _releaseHistory.clear());
      return;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      final items = decoded is List
          ? decoded.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _releaseHistory
            ..clear()
            ..addAll(items.reversed.take(20).toList().reversed);
        });
      }
    } catch (error) {
      _addLog('Históriu vydaní sa nepodarilo načítať: $error');
    }
  }




  Future<void> _checkProjectReadiness() async {
    final project = _project;
    if (project == null) return;

    if (mounted) {
      setState(() {
        _projectChecks
          ..clear()
          ..addAll(const <_ProjectCheck>[
            _ProjectCheck('pubspec.yaml', _CheckStatus.checking, 'Kontrolujem...'),
            _ProjectCheck('Priečinok lib', _CheckStatus.checking, 'Kontrolujem...'),
            _ProjectCheck('Android projekt', _CheckStatus.checking, 'Kontrolujem...'),
            _ProjectCheck('APK výstup', _CheckStatus.checking, 'Kontrolujem...'),
            _ProjectCheck('Flutter SDK', _CheckStatus.checking, 'Kontrolujem...'),
            _ProjectCheck('Git', _CheckStatus.checking, 'Kontrolujem...'),
          ]);
      });
    }
    _addLog('Kontrolujem pripravenosť projektu...');

    final root = project.projectPath;
    final pubspecExists = await File(path.join(root, 'pubspec.yaml')).exists();
    final libExists = await Directory(path.join(root, 'lib')).exists();
    final androidExists = await Directory(path.join(root, 'android')).exists();
    final apkDirectory = Directory(path.join(root, 'build', 'app', 'outputs', 'flutter-apk'));
    final apkOutputExists = await apkDirectory.exists();

    Future<_ProjectCheck> commandCheck(String label, String command, {bool optional = false}) async {
      try {
        final result = await Process.run(command, const <String>['--version'], runInShell: true);
        final output = '${result.stdout}'.trim();
        if (result.exitCode == 0) {
          String detail = output.isEmpty ? 'Dostupný' : output.split('\n').first.trim();

          // Na Windows môže výstup príkazu flutter --version obsahovať
          // nesprávne dekódované oddeľovacie znaky. Zobrazujeme preto iba
          // spoľahlivo rozpoznané ASCII údaje: verziu a kanál.
          if (command == 'flutter') {
            final version = RegExp(r'Flutter\s+([^\s]+)').firstMatch(output)?.group(1);
            final channel = RegExp(r'channel\s+([^\s]+)', caseSensitive: false)
                .firstMatch(output)
                ?.group(1);
            if (version != null) {
              detail = channel == null
                  ? 'Verzia: $version'
                  : 'Verzia: $version | Kanál: $channel';
            } else {
              detail = 'Flutter SDK je dostupný';
            }
          } else if (command == 'git') {
            final version = RegExp(r'git version\s+([^\s]+)', caseSensitive: false)
                .firstMatch(output)
                ?.group(1);
            detail = version == null ? 'Git je dostupný' : 'Verzia: $version';
          }

          return _ProjectCheck(label, _CheckStatus.ok, detail);
        }
      } catch (_) {}
      return _ProjectCheck(
        label,
        optional ? _CheckStatus.warning : _CheckStatus.error,
        optional ? 'Nenájdený - voliteľné' : 'Nenájdený alebo nie je v PATH',
      );
    }

    final flutterCheck = await commandCheck('Flutter SDK', 'flutter');
    final gitCheck = await commandCheck('Git', 'git', optional: true);

    final checks = <_ProjectCheck>[
      _ProjectCheck('pubspec.yaml', pubspecExists ? _CheckStatus.ok : _CheckStatus.error, pubspecExists ? 'Nájdený' : 'Chýba'),
      _ProjectCheck('Priečinok lib', libExists ? _CheckStatus.ok : _CheckStatus.error, libExists ? 'Nájdený' : 'Chýba'),
      _ProjectCheck('Android projekt', androidExists ? _CheckStatus.ok : _CheckStatus.error, androidExists ? 'Nájdený' : 'Chýba'),
      _ProjectCheck(
        'APK výstup',
        apkOutputExists ? _CheckStatus.ok : _CheckStatus.warning,
        apkOutputExists ? 'Priečinok existuje' : 'Zatiaľ nevytvorený – vznikne po APK builde',
      ),
      flutterCheck,
      gitCheck,
    ];

    if (mounted) {
      setState(() {
        _projectChecks
          ..clear()
          ..addAll(checks);
      });
    }
    final errors = checks.where((item) => item.status == _CheckStatus.error).length;
    final warnings = checks.where((item) => item.status == _CheckStatus.warning).length;
    _addLog('Kontrola projektu dokončená: $errors chýb, $warnings upozornení.');
  }

  Future<void> _loadProjectProfiles() async {
    try {
      final profiles = await _projectService.loadProfiles(_projectService.defaultProfilesDirectory);
      if (!mounted) return;
      setState(() {
        _projectProfiles
          ..clear()
          ..addAll(profiles);
        _activeProjectProfileId = _projectService.activeProfile(profiles)?.id;
        _projectProfilesLoading = false;
      });
      final active = _projectService.activeProfile(profiles);
      if (active != null && await Directory(active.projectPath).exists()) {
        _gitWorkspacePath = active.projectPath;
        _addLog('Project Profile obnovený: ${active.name}');
        await _openProjectPath(active.projectPath);
      }
      if (profiles.isEmpty) {
        unawaited(_showStartupWizardIfNeeded());
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _projectProfilesLoading = false);
      _addLog('Project Profiles: nepodarilo sa načítať profily: $error');
    }
  }

  Future<void> _persistProjectProfiles() async {
    final directory = _projectService.defaultProfilesDirectory;
    for (final profile in _projectProfiles) {
      await _projectService.saveProfile(directory, profile);
    }
  }

  Future<void> _activateProjectProfile(ProjectProfile profile) async {
    if (!await Directory(profile.projectPath).exists()) {
      if (mounted) _showError('Priečinok profilu už neexistuje: ${profile.projectPath}');
      return;
    }
    final activated = _projectService.activate(_projectProfiles, profile.id);
    setState(() {
      _projectProfiles
        ..clear()
        ..addAll(activated);
      _activeProjectProfileId = profile.id;
      _gitWorkspacePath = profile.projectPath;
    });
    await _persistProjectProfiles();
    await _rememberGitWorkspace(profile.projectPath);
    await _openProjectPath(profile.projectPath);
    await _refreshWorkspaceHealth();
  }

  Future<String?> _askProfileName(String title, String initialValue) async {
    final controller = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Názov profilu'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('ZRUŠIŤ')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()), child: const Text('ULOŽIŤ')),
        ],
      ),
    );
    controller.dispose();
    return value == null || value.trim().isEmpty ? null : value.trim();
  }

  Future<void> _createProjectProfile() async {
    final selected = await FilePicker.getDirectoryPath(
      dialogTitle: 'Vyber Flutter projekt pre nový profil',
      initialDirectory: _project?.projectPath,
      lockParentWindow: true,
    );
    if (selected == null || selected.trim().isEmpty) return;
    try {
      final info = await _pubspecService.readProject(selected);
      if (!mounted) return;
      final name = await _askProfileName('Nový Project Profile', info.projectName);
      if (name == null) return;
      final id = '${DateTime.now().millisecondsSinceEpoch}_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
      final platforms = <String>[
        if (await Directory(path.join(selected, 'windows')).exists()) 'windows',
        if (await Directory(path.join(selected, 'android')).exists()) 'android',
      ];
      final detectedBranch = await _gitService.currentBranch(selected) ?? '';
      final profile = ProjectProfile(
        id: id,
        name: name,
        projectPath: selected,
        exportPath: _windowsReleaseExportDirectory ?? _androidReleaseExportDirectory ?? '',
        gitRepository: '',
        flutterExecutable: 'flutter',
        platforms: platforms,
        gitBranch: detectedBranch,
        isActive: true,
      );
      setState(() {
        for (var i = 0; i < _projectProfiles.length; i++) {
          _projectProfiles[i] = _projectProfiles[i].copyWith(isActive: false);
        }
        _projectProfiles.add(profile);
        _activeProjectProfileId = profile.id;
      });
      await _persistProjectProfiles();
      await _activateProjectProfile(profile);
    } catch (error) {
      if (mounted) _showError('Profil sa nepodarilo vytvoriť: $error');
    }
  }

  Future<void> _renameProjectProfile(ProjectProfile profile) async {
    final name = await _askProfileName('Premenovať Project Profile', profile.name);
    if (name == null || !mounted) return;
    final index = _projectProfiles.indexWhere((item) => item.id == profile.id);
    if (index < 0) return;
    setState(() => _projectProfiles[index] = profile.copyWith(name: name));
    await _persistProjectProfiles();
  }

  Future<void> _editProjectProfileBranch(ProjectProfile profile) async {
    var detectedBranch = '';
    try {
      detectedBranch = await _gitService.currentBranch(profile.projectPath) ?? '';
    } catch (_) {}
    if (!mounted) return;
    final controller = TextEditingController(
      text: profile.gitBranch.trim().isNotEmpty ? profile.gitBranch : detectedBranch,
    );
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Git vetva projektu'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Preferovaná vetva',
                  helperText: detectedBranch.isEmpty
                      ? 'Zadaj vetvu projektu, napr. dev, develop alebo main.'
                      : 'Aktuálne zistená vetva: $detectedBranch',
                ),
              ),
              if (detectedBranch.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => controller.text = detectedBranch,
                  icon: const Icon(Icons.call_split_rounded),
                  label: Text('POUŽIŤ $detectedBranch'),
                ),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('ZRUŠIŤ')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('ULOŽIŤ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty || !mounted) return;
    final index = _projectProfiles.indexWhere((item) => item.id == profile.id);
    if (index < 0) return;
    setState(() => _projectProfiles[index] = profile.copyWith(gitBranch: value.trim()));
    await _persistProjectProfiles();
    _addLog('Project Profile ${profile.name}: preferovaná Git vetva = ${value.trim()}.');
  }

  Future<ProjectSnapshotInfo?> _createProjectSnapshot({String label = 'Before build'}) async {
    final workspace = _gitWorkspacePath;
    if (workspace == null || workspace.trim().isEmpty) {
      _showError('Najprv vyber pracovný projekt.');
      return null;
    }
    if (_snapshotRunning) return null;
    if (mounted) setState(() => _snapshotRunning = true);
    try {
      _addLog('Vytváram Project Snapshot: $label');
      final snapshot = await _snapshotService.createSnapshot(workspace, label: label);
      _lastProjectSnapshot = snapshot;
      _addLog('Project Snapshot vytvorený: ${snapshot.directory.path} (${snapshot.fileCount} súborov).');
      if (mounted) setState(() {});
      return snapshot;
    } catch (error) {
      _addLog('Project Snapshot zlyhal: $error');
      if (mounted) _showError('Project Snapshot sa nepodarilo vytvoriť: $error');
      return null;
    } finally {
      if (mounted) setState(() => _snapshotRunning = false);
    }
  }

  Future<void> _restoreLastProjectSnapshot() async {
    final snapshot = _lastProjectSnapshot;
    if (snapshot == null) {
      _showError('V tejto relácii ešte nebol vytvorený žiadny snapshot.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Obnoviť Project Snapshot?'),
        content: Text(
          'Zdrojové súbory projektu budú prepísané obsahom snapshotu "${snapshot.label}". '
          'Build cache a Git metadata sa neobnovujú.',
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('ZRUŠIŤ')),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.restore_rounded),
            label: const Text('OBNOVIŤ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _snapshotService.restoreSnapshot(snapshot);
      _addLog('Project Snapshot bol obnovený: ${snapshot.directory.path}');
      await _refreshGitWorkspace();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project Snapshot bol úspešne obnovený.')),
        );
      }
    } catch (error) {
      if (mounted) _showError('Obnovenie snapshotu zlyhalo: $error');
    }
  }

  Widget _buildSnapshotCenter() {
    final snapshot = _lastProjectSnapshot;
    return RMSectionCard(
      title: 'Project Snapshot',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            snapshot == null
                ? 'Pred One Click Buildom sa automaticky vytvorí lokálny snapshot zdrojových súborov.'
                : 'Posledný snapshot: ${snapshot.label} • ${snapshot.fileCount} súborov\n${snapshot.directory.path}',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _snapshotRunning ? null : () => _createProjectSnapshot(label: 'Manual snapshot'),
                icon: _snapshotRunning
                    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.camera_outlined),
                label: Text(_snapshotRunning ? 'VYTVÁRAM...' : 'VYTVORIŤ SNAPSHOT'),
              ),
              OutlinedButton.icon(
                onPressed: snapshot == null || _snapshotRunning ? null : _restoreLastProjectSnapshot,
                icon: const Icon(Icons.restore_rounded),
                label: const Text('OBNOVIŤ POSLEDNÝ'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _duplicateProjectProfile(ProjectProfile profile) async {
    final name = await _askProfileName('Duplikovať Project Profile', '${profile.name} – kópia');
    if (name == null || !mounted) return;
    final copy = profile.copyWith(
      id: '${DateTime.now().millisecondsSinceEpoch}_copy',
      name: name,
      isActive: false,
    );
    setState(() => _projectProfiles.add(copy));
    await _projectService.saveProfile(_projectService.defaultProfilesDirectory, copy);
  }

  Future<void> _deleteProjectProfile(ProjectProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Odstrániť Project Profile?'),
        content: Text('Profil „${profile.name}“ bude odstránený. Projektové súbory zostanú nedotknuté.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('ZRUŠIŤ')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('ODSTRÁNIŤ')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _projectProfiles.removeWhere((item) => item.id == profile.id);
      if (_activeProjectProfileId == profile.id) _activeProjectProfileId = null;
    });
    await _projectService.deleteProfile(_projectService.defaultProfilesDirectory, profile.id);
  }

  Future<void> _showStartupWizardIfNeeded() async {
    if (_startupWizardShown || _projectProfiles.isNotEmpty || !mounted) return;
    _startupWizardShown = true;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: <Widget>[
            Icon(Icons.auto_awesome_rounded),
            SizedBox(width: 10),
            Expanded(child: Text('Startup Wizard')),
          ],
        ),
        content: const SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Release Manager je pripravený vytvoriť prvý Project Profile a pracovnú štruktúru.'),
              SizedBox(height: 12),
              Text('• NOVÝ PROFIL – vyberieš Flutter projekt a vytvoríš profil.'),
              Text('• IMPORT – obnovíš profily z .rmworkspace súboru.'),
              Text('• PRESKOČIŤ – sprievodcu zatvoríš a projekt nastavíš neskôr.'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('skip'),
            child: const Text('PRESKOČIŤ'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop('import'),
            icon: const Icon(Icons.download_rounded),
            label: const Text('IMPORT'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop('create'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('NOVÝ PROFIL'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'create') await _createProjectProfile();
    if (action == 'import') await _importWorkspaceBundle();
  }

  Future<void> _refreshWorkspaceHealth() async {
    final workspace = _gitWorkspacePath ?? _project?.projectPath;
    if (workspace == null || workspace.trim().isEmpty) return;
    if (mounted) setState(() => _workspaceHealthLoading = true);
    try {
      final health = await _workspaceManager.health(workspace);
      if (!mounted) return;
      setState(() {
        _workspaceHealth = health;
        _workspaceHealthLoading = false;
      });
    } catch (error) {
      if (mounted) setState(() => _workspaceHealthLoading = false);
      _addLog('Workspace Health: $error');
    }
  }

  Future<void> _repairWorkspace() async {
    final workspace = _gitWorkspacePath ?? _project?.projectPath;
    if (workspace == null || workspace.trim().isEmpty) {
      _showError('Najprv vyber projekt alebo Project Profile.');
      return;
    }
    try {
      await _workspaceManager.repair(workspace);
      await _refreshWorkspaceHealth();
      _addLog('Workspace Manager: pracovná štruktúra je pripravená.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workspace bol pripravený a skontrolovaný.')),
        );
      }
    } catch (error) {
      if (mounted) _showError('Workspace sa nepodarilo pripraviť: $error');
    }
  }

  Future<void> _exportWorkspaceBundle() async {
    final destination = await FilePicker.saveFile(
      dialogTitle: 'Exportovať Release Manager Workspace',
      fileName: 'ReleaseManager_Workspace_${DateTime.now().toIso8601String().substring(0, 10)}.rmworkspace',
      type: FileType.custom,
      allowedExtensions: const <String>['rmworkspace'],
      lockParentWindow: true,
    );
    if (destination == null || destination.trim().isEmpty) return;
    final output = destination.toLowerCase().endsWith('.rmworkspace')
        ? destination
        : '$destination.rmworkspace';
    try {
      await _workspaceManager.exportBundle(
        destinationPath: output,
        profiles: _projectProfiles,
        activeProfileId: _activeProjectProfileId,
      );
      _addLog('Workspace export vytvorený: $output');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Workspace exportovaný: $output')),
        );
      }
    } catch (error) {
      if (mounted) _showError('Workspace export zlyhal: $error');
    }
  }

  Future<void> _importWorkspaceBundle() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Importovať Release Manager Workspace',
      type: FileType.custom,
      allowedExtensions: const <String>['rmworkspace'],
      allowMultiple: false,
      lockParentWindow: true,
    );
    final source = result?.files.single.path;
    if (source == null || source.trim().isEmpty) return;
    try {
      final imported = await _workspaceManager.importBundle(source);
      if (!mounted) return;
      setState(() {
        _projectProfiles
          ..clear()
          ..addAll(imported.profiles);
        _activeProjectProfileId = imported.activeProfileId;
      });
      await _persistProjectProfiles();
      ProjectProfile? active;
      for (final profile in _projectProfiles) {
        if (profile.id == _activeProjectProfileId) {
          active = profile;
          break;
        }
      }
      if (active != null && await Directory(active.projectPath).exists()) {
        await _activateProjectProfile(active);
      }
      _addLog('Workspace import dokončený: $source');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workspace bol úspešne importovaný.')),
        );
      }
    } catch (error) {
      if (mounted) _showError('Workspace import zlyhal: $error');
    }
  }

  Widget _buildLocalBuildAssistant() {
    final workspace = _gitWorkspacePath ?? _project?.projectPath;
    final ready = workspace != null && workspace.trim().isNotEmpty;
    final healthOk = _workspaceHealth.isNotEmpty && _workspaceHealth.every((item) => item.ok || item.name == 'Git');
    return RMSectionCard(
      title: 'Local Build Assistant + Workspace Manager',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  ready ? workspace : 'Najprv vyber Project Profile alebo projekt.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                healthOk ? Icons.verified_rounded : Icons.health_and_safety_outlined,
                color: healthOk ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: !ready || _busy ? null : _repairWorkspace,
                icon: const Icon(Icons.build_circle_outlined),
                label: const Text('PRIPRAVIŤ WORKSPACE'),
              ),
              OutlinedButton.icon(
                onPressed: !ready || _busy ? null : _refreshWorkspaceHealth,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('WORKSPACE HEALTH'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _exportWorkspaceBundle,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('EXPORT .RMWORKSPACE'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _importWorkspaceBundle,
                icon: const Icon(Icons.download_rounded),
                label: const Text('IMPORT .RMWORKSPACE'),
              ),
            ],
          ),
          if (_workspaceHealthLoading) ...<Widget>[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_workspaceHealth.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _workspaceHealth.map((item) => Tooltip(
                message: item.path,
                child: Chip(
                  avatar: Icon(
                    item.ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    size: 18,
                    color: item.ok ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
                  ),
                  label: Text(item.name),
                ),
              )).toList(growable: false),
            ),
          ],
          const Divider(height: 28),
          const Text('Development Center', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: !ready || _oneClickBuildRunning ? null : _runOneClickBuild,
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('ONE CLICK BUILD'),
              ),
              OutlinedButton.icon(
                onPressed: !ready || _busy ? null : () => _runWorkspaceFlutterStep(workspace, const <String>['analyze'], 'Flutter analyze'),
                icon: const Icon(Icons.manage_search_rounded),
                label: const Text('ANALYZE'),
              ),
              OutlinedButton.icon(
                onPressed: !ready || _busy ? null : () => _runWorkspaceFlutterStep(workspace, const <String>['test'], 'Flutter test'),
                icon: const Icon(Icons.science_outlined),
                label: const Text('TEST'),
              ),
              OutlinedButton.icon(
                onPressed: !ready || _busy ? null : () => _runWorkspaceFlutterStep(workspace, const <String>['build', 'windows', '--release'], 'Windows Release build'),
                icon: const Icon(Icons.desktop_windows_rounded),
                label: const Text('WINDOWS'),
              ),
              OutlinedButton.icon(
                onPressed: !ready || _busy ? null : () => _runWorkspaceFlutterStep(workspace, const <String>['build', 'apk', '--release'], 'Android APK build'),
                icon: const Icon(Icons.android_rounded),
                label: const Text('ANDROID APK'),
              ),
              OutlinedButton.icon(
                onPressed: !ready || _busy ? null : () => _runWorkspaceFlutterStep(workspace, const <String>['build', 'appbundle', '--release'], 'Android AAB build'),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('ANDROID AAB'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'One Click Build používa existujúci overený reťazec: clean → pub get → analyze → test → Windows Release → report → Release ZIP.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _pickProject() async {
    String? selected;
    try {
      selected = await FilePicker.getDirectoryPath(
        dialogTitle: 'Vyber Flutter projekt STAVBY PRO',
      );
    } catch (error, stackTrace) {
      await _handleProjectOpenError(
        'Výber priečinka projektu',
        error,
        stackTrace,
      );
      return;
    }

    if (selected == null) {
      _addLog('Výber projektu bol zrušený.');
      return;
    }

    await _openProjectPath(selected);
  }

  Future<void> _openProjectPath(String selected) async {
    if (!mounted) return;
    setState(() => _busy = true);
    _addLog('Načítavam projekt: $selected');

    try {
      _addLog('Načítanie projektu – Načítanie pubspec.yaml...');
      late final ProjectInfo project;
      try {
        project = await _pubspecService.readProject(selected);
        _addLog('Načítanie projektu – Načítanie pubspec.yaml dokončené.');
      } catch (error, stackTrace) {
        await _handleProjectOpenError(
          'Načítanie pubspec.yaml',
          error,
          stackTrace,
          projectPath: selected,
        );
        return;
      }
      if (!mounted) return;

      setState(() {
        _project = project;
        _apkPath = null;
        _apkSizeBytes = null;
        _apkSha256 = null;
        _versionJsonPreview = null;
        _releaseNotesPreview = null;
        _githubReleasePreview = null;
        _androidExportedApkPath = null;
        _completedApkBuildSteps.clear();
      });
      _addLog('Projekt otvorený: ${project.projectName}');
      _addLog('Načítaná verzia ${project.fullVersion}.');
      await _rememberProjectPath(selected);

      await _runProjectOpenStep(
        'Načítanie histórie vydaní',
        _loadReleaseHistory,
        projectPath: selected,
      );
      if (!mounted) return;

      await _runProjectOpenStep(
        'Kontrola pripravenosti projektu',
        _checkProjectReadiness,
        projectPath: selected,
      );
      if (!mounted) return;

      await _runProjectOpenStep(
        'Automatická analýza APK',
        () => _analyzeApk(silentIfMissing: true),
        projectPath: selected,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rememberProjectPath(String projectPath) async {
    final normalized = projectPath.trim();
    if (normalized.isEmpty) return;
    final updated = <String>[
      normalized,
      ..._recentProjectPaths.where((item) => item != normalized),
    ];
    if (updated.length > 6) updated.removeRange(6, updated.length);
    if (mounted) {
      setState(() {
        _recentProjectPaths
          ..clear()
          ..addAll(updated);
      });
    }
    await _appSettingsService.saveRecentProjectPaths(updated);
  }

  Future<void> _removeRecentProject(String projectPath) async {
    final updated = _recentProjectPaths.where((item) => item != projectPath).toList();
    setState(() {
      _recentProjectPaths
        ..clear()
        ..addAll(updated);
    });
    await _appSettingsService.saveRecentProjectPaths(updated);
  }

  Future<bool> _recentProjectExists(String projectPath) async {
    return Directory(projectPath).exists();
  }

  Future<bool> _runProjectOpenStep(
    String step,
    Future<void> Function() action, {
    required String projectPath,
  }) async {
    _addLog('Načítanie projektu – $step...');
    try {
      await action();
      _addLog('Načítanie projektu – $step dokončené.');
      return true;
    } catch (error, stackTrace) {
      await _handleProjectOpenError(
        step,
        error,
        stackTrace,
        projectPath: projectPath,
      );
      return false;
    }
  }

  Future<void> _handleProjectOpenError(
    String step,
    Object error,
    StackTrace stackTrace, {
    String? projectPath,
  }) async {
    await _writeCrashLog(
      error,
      stackTrace,
      step: step,
      projectPath: projectPath,
    );
    _addLog('CHYBA pri kroku „$step“: $error');
    if (!mounted) return;
    _showError(
      'Projekt sa nepodarilo úplne načítať. Aplikácia zostáva spustená. '
      'Podrobnosti sú v súbore release_manager_crash.log.\n\nKrok: $step\nChyba: $error',
    );
  }

  Future<bool> _runFlutterCommand(
    List<String> arguments, {
    required String label,
  }) async {
    final project = _project;
    if (project == null) {
      _showError('Najprv vyber projekt STAVBY PRO.');
      return false;
    }

    setState(() {
      _busy = true;
      _activeCommand = label;
    });
    _startFlutterStepProgress(label);

    _addLog('▶ flutter ${arguments.join(' ')}');
    final commandOutput = <String>[];

    try {
      final process = await Process.start(
        'flutter',
        arguments,
        workingDirectory: project.projectPath,
        runInShell: true,
      );

      final stdoutDone = process.stdout
          .transform(systemEncoding.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            commandOutput.add(line);
            _addLog(line);
          })
          .asFuture<void>();
      final stderrDone = process.stderr
          .transform(systemEncoding.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            commandOutput.add('CHYBA: $line');
            _addLog('CHYBA: $line');
          })
          .asFuture<void>();

      final exitCode = await process.exitCode;
      await Future.wait<void>(<Future<void>>[stdoutDone, stderrDone]);

      final analyzeAccepted = label == 'Flutter analyze'
          ? _acceptAnalyzeResult(exitCode: exitCode, output: commandOutput)
          : exitCode == 0;
      if (analyzeAccepted) {
        _finishFlutterStepProgress(success: true);
        if (mounted) {
          setState(() => _completedApkBuildSteps.add(label));
        }
        if (label == 'Flutter analyze' && exitCode != 0) {
          _addLog('⚠ Flutter analyze obsahuje iba upozornenia. Professional Mode pokračuje v builde.');
        } else {
          _addLog('✔ $label bol úspešne dokončený.');
        }
        return true;
      }

      _finishFlutterStepProgress(success: false);
      _addLog('✖ $label zlyhal. Návratový kód: $exitCode.');
      await _showBuildFailureDialog(
        projectName: project.projectName,
        projectPath: project.projectPath,
        label: label,
        arguments: arguments,
        output: commandOutput,
        exitCode: exitCode,
      );
      return false;
    } on ProcessException catch (error, stackTrace) {
      _finishFlutterStepProgress(success: false);
      commandOutput.add('ProcessException: ${error.message}');
      _addLog('CHYBA: Flutter sa nepodarilo spustiť: ${error.message}');
      await _showBuildFailureDialog(
        projectName: project.projectName,
        projectPath: project.projectPath,
        label: label,
        arguments: arguments,
        output: commandOutput,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } catch (error, stackTrace) {
      _finishFlutterStepProgress(success: false);
      commandOutput.add('CHYBA: $error');
      _addLog('CHYBA: $error');
      await _writeCrashLog(
        error,
        stackTrace,
        step: label,
        projectPath: project.projectPath,
      );
      await _showBuildFailureDialog(
        projectName: project.projectName,
        projectPath: project.projectPath,
        label: label,
        arguments: arguments,
        output: commandOutput,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeCommand = null;
        });
      }
    }
  }

  String _flutterStepDetail({
    required String label,
    required String idleText,
  }) {
    if (_activeCommand == label) {
      return 'Odhad ${(_flutterStepEstimatedProgress * 100).round()} % • $_flutterStepElapsedText';
    }
    if (_completedApkBuildSteps.contains(label)) {
      return 'Dokončené • 100 %';
    }
    return idleText;
  }

  double? _flutterStepProgress(String label) {
    if (_activeCommand == label) return _flutterStepEstimatedProgress;
    if (_completedApkBuildSteps.contains(label)) return 1.0;
    return null;
  }



  Future<bool> _checkWindowsEnvironment({bool showResult = true}) async {
    final project = _project;
    if (project == null) {
      if (showResult) _showError('Najprv rozbaľ alebo vyber Windows DEV projekt.');
      return false;
    }

    if (mounted) {
      setState(() {
        _busy = true;
        _activeCommand = 'Kontrola Windows prostredia';
        for (final key in _windowsWorkspace.environmentChecks.keys) {
          _windowsWorkspace.environmentChecks[key] = null;
        }
        _windowsWorkspace.environmentDetails.clear();
      });
    }
    _addLog('▶ Spúšťam rozšírenú predletovú kontrolu Windows Workspace...');

    try {
      final pubspecFile = File(path.join(project.projectPath, 'pubspec.yaml'));
      final analysisOptionsFile = File(path.join(project.projectPath, 'analysis_options.yaml'));
      final libDirectory = Directory(path.join(project.projectPath, 'lib'));
      final windowsDirectory = Directory(path.join(project.projectPath, 'windows'));
      final pubspecExists = await pubspecFile.exists();
      final analysisOptionsExists = await analysisOptionsFile.exists();
      final libExists = await libDirectory.exists();
      final windowsExists = await windowsDirectory.exists();
      final versionValid = project.version.trim().isNotEmpty && project.build > 0;

      bool flutterAvailable = false;
      bool dartAvailable = false;
      bool gitAvailable = false;
      bool windowsDesktopEnabled = false;
      String flutterDetail = 'Flutter SDK nebolo nájdené.';
      String dartDetail = 'Dart SDK nebolo nájdené.';
      String gitDetail = 'Git nebol nájdený.';
      String windowsDetail = windowsExists
          ? 'Projekt obsahuje natívny priečinok windows.'
          : 'Projekt neobsahuje priečinok windows.';

      try {
        final flutterVersion = await Process.run(
          'flutter',
          const <String>['--version'],
          workingDirectory: project.projectPath,
          runInShell: true,
        );
        flutterAvailable = flutterVersion.exitCode == 0;
        final output = '${flutterVersion.stdout}\n${flutterVersion.stderr}';
        final firstLine = output
            .split(RegExp(r'[\r\n]+'))
            .firstWhere((line) => line.trim().isNotEmpty, orElse: () => 'Flutter SDK je dostupné.');
        flutterDetail = flutterAvailable
            ? firstLine.trim()
            : 'flutter --version skončil s kódom ${flutterVersion.exitCode}.';

        if (flutterAvailable) {
          final flutterConfig = await Process.run(
            'flutter',
            const <String>['config'],
            workingDirectory: project.projectPath,
            runInShell: true,
          );
          final configOutput = '${flutterConfig.stdout}\n${flutterConfig.stderr}'.toLowerCase();
          final explicitlyEnabled = configOutput.contains('enable-windows-desktop: true');
          final explicitlyDisabled = configOutput.contains('enable-windows-desktop: false');
          windowsDesktopEnabled = windowsExists && !explicitlyDisabled;
          if (explicitlyEnabled) {
            windowsDetail = 'Flutter Windows Desktop je zapnutý a projekt obsahuje priečinok windows.';
          } else if (explicitlyDisabled) {
            windowsDetail = 'Flutter Windows Desktop je vypnutý. Spusti flutter config --enable-windows-desktop.';
          } else if (windowsExists) {
            windowsDetail = 'Windows Desktop je dostupný cez existujúci priečinok windows.';
          }
        }
      } catch (error) {
        flutterDetail = 'Flutter SDK sa nepodarilo spustiť: $error';
      }

      try {
        final dartVersion = await Process.run(
          'dart',
          const <String>['--version'],
          workingDirectory: project.projectPath,
          runInShell: true,
        );
        dartAvailable = dartVersion.exitCode == 0;
        final output = '${dartVersion.stdout}\n${dartVersion.stderr}'.trim();
        dartDetail = dartAvailable
            ? (output.isEmpty ? 'Dart SDK je dostupné.' : output.split(RegExp(r'[\r\n]+')).first.trim())
            : 'dart --version skončil s kódom ${dartVersion.exitCode}.';
      } catch (error) {
        dartDetail = 'Dart SDK sa nepodarilo spustiť: $error';
      }

      try {
        final gitVersion = await Process.run(
          'git',
          const <String>['--version'],
          workingDirectory: project.projectPath,
          runInShell: true,
        );
        gitAvailable = gitVersion.exitCode == 0;
        final output = '${gitVersion.stdout}\n${gitVersion.stderr}'.trim();
        gitDetail = gitAvailable
            ? (output.isEmpty ? 'Git je dostupný.' : output.split(RegExp(r'[\r\n]+')).first.trim())
            : 'git --version skončil s kódom ${gitVersion.exitCode}.';
      } catch (error) {
        gitDetail = 'Git sa nepodarilo spustiť: $error';
      }

      if (mounted) {
        setState(() {
          _windowsWorkspace.environmentChecks['Flutter SDK'] = flutterAvailable;
          _windowsWorkspace.environmentChecks['Dart SDK'] = dartAvailable;
          _windowsWorkspace.environmentChecks['Git'] = gitAvailable;
          _windowsWorkspace.environmentChecks['pubspec.yaml'] = pubspecExists;
          _windowsWorkspace.environmentChecks['analysis_options.yaml'] = analysisOptionsExists;
          _windowsWorkspace.environmentChecks['Priečinok lib'] = libExists;
          _windowsWorkspace.environmentChecks['Windows Desktop'] = windowsDesktopEnabled;
          _windowsWorkspace.environmentChecks['Priečinok windows'] = windowsExists;
          _windowsWorkspace.environmentChecks['Verzia projektu'] = versionValid;
          _windowsWorkspace.environmentDetails['Flutter SDK'] = flutterDetail;
          _windowsWorkspace.environmentDetails['Dart SDK'] = dartDetail;
          _windowsWorkspace.environmentDetails['Git'] = gitDetail;
          _windowsWorkspace.environmentDetails['pubspec.yaml'] = pubspecExists
              ? 'Nájdené: ${pubspecFile.path}'
              : 'Súbor pubspec.yaml neexistuje.';
          _windowsWorkspace.environmentDetails['analysis_options.yaml'] = analysisOptionsExists
              ? 'Nájdené: ${analysisOptionsFile.path}'
              : 'Súbor analysis_options.yaml neexistuje.';
          _windowsWorkspace.environmentDetails['Priečinok lib'] = libExists
              ? 'Nájdené: ${libDirectory.path}'
              : 'Priečinok lib neexistuje.';
          _windowsWorkspace.environmentDetails['Windows Desktop'] = windowsDetail;
          _windowsWorkspace.environmentDetails['Priečinok windows'] = windowsExists
              ? 'Nájdené: ${windowsDirectory.path}'
              : 'Priečinok windows neexistuje.';
          _windowsWorkspace.environmentDetails['Verzia projektu'] = versionValid
              ? 'Načítaná verzia ${project.version}, build ${project.build} (${project.releaseVariant.isEmpty ? 'bez označenia vetvy' : project.releaseVariant}).'
              : 'Verzia alebo build číslo v pubspec.yaml nie sú platné.';
          _windowsWorkspace.environmentCheckedAt = DateTime.now();
        });
      }

      final success = _windowsWorkspace.environmentChecks.values.every((value) => value == true);
      _addLog(success
          ? '✔ Rozšírená predletová kontrola Windows Workspace bola úspešná.'
          : '✖ Predletová kontrola Windows Workspace našla problém.');
      if (showResult && mounted) {
        if (success) {
          _showSuccess('Predletová kontrola bola úspešná. Windows Workspace je pripravený na build.');
        } else {
          _showError('Predletová kontrola našla problém. Pozri detail jednotlivých položiek.');
        }
      }
      return success;
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeCommand = null;
        });
      }
    }
  }

  Future<void> _copyWindowsPreflightReport() async {
    final project = _project;
    if (project == null || _windowsWorkspace.environmentCheckedAt == null) {
      _showError('Najprv spusti predletovú kontrolu Windows Workspace.');
      return;
    }
    final buffer = StringBuffer()
      ..writeln('STAVBY PRO – WINDOWS PREFLIGHT REPORT')
      ..writeln('Projekt: ${project.projectName}')
      ..writeln('Cesta: ${project.projectPath}')
      ..writeln('Verzia: ${project.fullVersion}')
      ..writeln('Kontrola: ${_windowsWorkspace.environmentCheckedAt!.toIso8601String()}')
      ..writeln();
    for (final entry in _windowsWorkspace.environmentChecks.entries) {
      buffer.writeln('${entry.value == true ? 'OK' : 'CHYBA'} | ${entry.key} | ${_windowsWorkspace.environmentDetails[entry.key] ?? ''}');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    _showSuccess('Predletový report bol skopírovaný do schránky.');
  }

  Widget _buildWindowsEnvironmentPanel() {
    final checkedAt = _windowsWorkspace.environmentCheckedAt;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const _ColorIcon(icon: Icons.health_and_safety_rounded, color: Color(0xFF00ACC1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Kontrola Windows prostredia', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      checkedAt == null
                          ? 'Pred buildom over Flutter SDK a povinné súčasti projektu.'
                          : 'Posledná kontrola: ${checkedAt.toLocal().toString().substring(0, 19)}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _busy || _project == null ? null : _checkWindowsEnvironment,
                    icon: _activeCommand == 'Kontrola Windows prostredia'
                        ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.fact_check_rounded),
                    label: const Text('OVERIŤ PROJEKT'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy || _windowsWorkspace.environmentCheckedAt == null
                        ? null
                        : _copyWindowsPreflightReport,
                    icon: const Icon(Icons.copy_all_rounded),
                    label: const Text('KOPÍROVAŤ REPORT'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._windowsWorkspace.environmentChecks.entries.map((entry) {
            final value = entry.value;
            final color = value == null
                ? const Color(0xFF78909C)
                : value
                    ? const Color(0xFF43A047)
                    : const Color(0xFFE53935);
            final icon = value == null
                ? Icons.help_outline_rounded
                : value
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(icon, color: color, size: 21),
                  const SizedBox(width: 10),
                  SizedBox(width: 140, child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Expanded(child: Text(_windowsWorkspace.environmentDetails[entry.key] ?? 'Zatiaľ nekontrolované.')),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAndroidWorkspaceCompactOverview() {
    final environmentReady =
        _projectChecks.isNotEmpty &&
        _projectChecks.every((item) => item.status == _CheckStatus.ok);
    final cleanDone = _completedApkBuildSteps.contains('Flutter clean');
    final pubGetDone = _completedApkBuildSteps.contains('Flutter pub get');
    final analyzeDone = _completedApkBuildSteps.contains('Flutter analyze');
    final apkDone = _apkPath != null && _apkSha256 != null;
    final aabDone = _aabPath != null && _aabSha256 != null;
    final exportDone = _androidExportedApkPath != null;

    final completedCount = <bool>[
      environmentReady,
      cleanDone,
      pubGetDone,
      analyzeDone,
      apkDone,
      aabDone,
      exportDone,
    ].where((value) => value).length;
    final progress = completedCount / 7;

    Widget statusTile({
      required String title,
      required String value,
      required IconData icon,
      required bool completed,
    }) {
      final color = completed
          ? const Color(0xFF43A047)
          : const Color(0xFF78909C);
      return Container(
        width: 190,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: color,
              size: 17,
            ),
          ],
        ),
      );
    }

    return RMSectionCard(
      title: 'Android Workspace 2.0',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const _ColorIcon(
                icon: Icons.android_rounded,
                color: Color(0xFF43A047),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _busy ? (_activeCommand ?? 'Android proces beží') : 'Android release pipeline',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      '$completedCount zo 7 hlavných krokov dokončených',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (progress == 1
                          ? const Color(0xFF43A047)
                          : const Color(0xFF2E7D32))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  progress == 1 ? 'READY' : '${(progress * 100).round()} %',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: progress == 1
                        ? const Color(0xFF43A047)
                        : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress, minHeight: 7),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              statusTile(
                title: 'Prostredie',
                value: environmentReady ? 'Pripravené' : 'Vyžaduje kontrolu',
                icon: Icons.health_and_safety_rounded,
                completed: environmentReady,
              ),
              statusTile(
                title: 'Clean + Pub Get',
                value: cleanDone && pubGetDone ? 'Dokončené' : 'Čaká',
                icon: Icons.cleaning_services_rounded,
                completed: cleanDone && pubGetDone,
              ),
              statusTile(
                title: 'Analyze',
                value: analyzeDone ? 'Dokončené' : 'Čaká',
                icon: Icons.manage_search_rounded,
                completed: analyzeDone,
              ),
              statusTile(
                title: 'Release APK',
                value: apkDone ? path.basename(_apkPath!) : 'Čaká',
                icon: Icons.android_rounded,
                completed: apkDone,
              ),
              statusTile(
                title: 'Release AAB',
                value: aabDone ? path.basename(_aabPath!) : 'Čaká',
                icon: Icons.inventory_2_rounded,
                completed: aabDone,
              ),
              statusTile(
                title: 'Export',
                value: exportDone ? 'Hotový' : 'Čaká',
                icon: Icons.file_upload_rounded,
                completed: exportDone,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _busy || _project == null ? null : _runFullBuild,
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('KOMPLETNÝ ANDROID BUILD'),
              ),
              OutlinedButton.icon(
                onPressed: _busy || _project == null
                    ? null
                    : () => _runFlutterCommand(
                          <String>['analyze'],
                          label: 'Flutter analyze',
                        ),
                icon: const Icon(Icons.manage_search_rounded),
                label: const Text('ANALYZE'),
              ),
              OutlinedButton.icon(
                onPressed: _busy || _project == null
                    ? null
                    : () async {
                        final ok = await _runFlutterCommand(
                          <String>['build', 'appbundle', '--release'],
                          label: 'Release AAB build',
                        );
                        if (ok) await _analyzeAab();
                      },
                icon: const Icon(Icons.inventory_2_rounded),
                label: const Text('BUILD AAB'),
              ),
              OutlinedButton.icon(
                onPressed: _busy || _apkPath == null ? null : _openApkFolder,
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('OTVORIŤ VÝSTUP'),
              ),
              OutlinedButton.icon(
                onPressed: _busy || _apkSha256 == null ? null : _exportAndroidRelease,
                icon: const Icon(Icons.file_upload_rounded),
                label: const Text('EXPORT'),
              ),
            ],
          ),
          if (_apkPath != null || _aabPath != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Výstupné artefakty', style: TextStyle(fontWeight: FontWeight.w800)),
                  if (_apkPath != null) Text('APK: $_apkPath', maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (_aabPath != null) Text('AAB: $_aabPath', maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWindowsWorkspaceSummary() {
    final rows = <({String title, bool done, IconData icon})>[
      (title: 'Kontrola prostredia', done: _windowsWorkspace.environmentChecks.values.every((value) => value == true), icon: Icons.health_and_safety_rounded),
      (title: 'Flutter clean', done: _windowsWorkspace.completedBuildSteps.contains('Windows Flutter clean'), icon: Icons.cleaning_services_rounded),
      (title: 'Flutter pub get', done: _windowsWorkspace.completedBuildSteps.contains('Windows Flutter pub get'), icon: Icons.inventory_2_rounded),
      (title: 'Flutter analyze', done: _windowsWorkspace.completedBuildSteps.contains('Windows Flutter analyze'), icon: Icons.manage_search_rounded),
      (title: 'Windows build', done: _windowsWorkspace.completedBuildSteps.contains('Windows Release build'), icon: Icons.desktop_windows_rounded),
      (title: 'Kontrola EXE', done: _windowsWorkspace.completedBuildSteps.contains('Kontrola Windows EXE'), icon: Icons.verified_rounded),
      (title: 'Test EXE', done: _windowsWorkspace.completedBuildSteps.contains('Spustenie Windows EXE'), icon: Icons.play_circle_rounded),
      (title: 'Export', done: _windowsExportedPath != null, icon: Icons.file_upload_rounded),
    ];
    return RMSectionCard(
      title: 'Stav Windows Workspace',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: rows.map((row) => Container(
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: (row.done ? const Color(0xFF43A047) : const Color(0xFF78909C)).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (row.done ? const Color(0xFF43A047) : const Color(0xFF78909C)).withValues(alpha: 0.28)),
          ),
          child: Row(children: <Widget>[
            Icon(row.icon, color: row.done ? const Color(0xFF43A047) : const Color(0xFF78909C), size: 20),
            const SizedBox(width: 9),
            Expanded(child: Text(row.title, style: const TextStyle(fontWeight: FontWeight.w700))),
            Icon(row.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: row.done ? const Color(0xFF43A047) : const Color(0xFF78909C), size: 18),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _buildWindowsWorkspaceCompactOverview() {
    final environmentReady =
        _windowsWorkspace.environmentChecks.isNotEmpty &&
        _windowsWorkspace.environmentChecks.values.every((value) => value == true);
    final analyzeDone =
        _windowsWorkspace.completedBuildSteps.contains('Windows Flutter analyze');
    final buildDone =
        _windowsWorkspace.completedBuildSteps.contains('Windows Release build');
    final exeVerified =
        _windowsWorkspace.completedBuildSteps.contains('Kontrola Windows EXE');
    final exeTested =
        _windowsWorkspace.completedBuildSteps.contains('Spustenie Windows EXE');
    final exportDone = _windowsExportedPath != null;

    final completedCount = <bool>[
      environmentReady,
      analyzeDone,
      buildDone,
      exeVerified,
      exeTested,
      exportDone,
    ].where((value) => value).length;
    final progress = completedCount / 6;

    Widget statusTile({
      required String title,
      required String value,
      required IconData icon,
      required bool completed,
    }) {
      final color = completed
          ? const Color(0xFF43A047)
          : const Color(0xFF78909C);
      return Container(
        width: 190,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: color,
              size: 17,
            ),
          ],
        ),
      );
    }

    return RMSectionCard(
      title: 'Windows Workspace 2.0',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const _ColorIcon(
                icon: Icons.desktop_windows_rounded,
                color: Color(0xFF1565C0),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _busy ? (_activeCommand ?? 'Windows proces beží') : 'Windows DEV pipeline',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      '$completedCount zo 6 hlavných krokov dokončených',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (progress == 1
                          ? const Color(0xFF43A047)
                          : const Color(0xFF1565C0))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  progress == 1 ? 'READY' : '${(progress * 100).round()} %',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: progress == 1
                        ? const Color(0xFF43A047)
                        : const Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              statusTile(
                title: 'Prostredie',
                value: environmentReady ? 'Pripravené' : 'Vyžaduje kontrolu',
                icon: Icons.health_and_safety_rounded,
                completed: environmentReady,
              ),
              statusTile(
                title: 'Analyze',
                value: analyzeDone ? 'Dokončené' : 'Čaká',
                icon: Icons.manage_search_rounded,
                completed: analyzeDone,
              ),
              statusTile(
                title: 'Windows build',
                value: buildDone ? 'Release vytvorený' : 'Čaká',
                icon: Icons.build_circle_rounded,
                completed: buildDone,
              ),
              statusTile(
                title: 'EXE kontrola',
                value: exeVerified ? 'Súbor nájdený' : 'Neoverené',
                icon: Icons.verified_rounded,
                completed: exeVerified,
              ),
              statusTile(
                title: 'EXE test',
                value: exeTested ? 'PASS' : 'Neotestované',
                icon: Icons.play_circle_rounded,
                completed: exeTested,
              ),
              statusTile(
                title: 'Export',
                value: exportDone ? 'Hotový' : 'Čaká',
                icon: Icons.file_upload_rounded,
                completed: exportDone,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _busy || _project == null ? null : _runFullWindowsDevBuild,
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('KOMPLETNÝ BUILD'),
              ),
              OutlinedButton.icon(
                onPressed: _busy || _project == null
                    ? null
                    : () => _runWindowsFlutterCommand(
                          <String>['analyze'],
                          label: 'Windows Flutter analyze',
                        ),
                icon: const Icon(Icons.manage_search_rounded),
                label: const Text('ANALYZE'),
              ),
              OutlinedButton.icon(
                onPressed: _busy || _windowsBuiltExePath == null
                    ? null
                    : _launchWindowsDevExe,
                icon: const Icon(Icons.play_circle_rounded),
                label: const Text('TEST EXE'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ||
                        _windowsBuiltExePath == null ||
                        !_windowsWorkspace.completedBuildSteps
                            .contains('Spustenie Windows EXE')
                    ? null
                    : _exportWindowsDevRelease,
                icon: const Icon(Icons.file_upload_rounded),
                label: const Text('EXPORT'),
              ),
            ],
          ),
          if (_windowsBuiltExePath != null) ...<Widget>[
            const SizedBox(height: 10),
            SelectableText(
              _windowsBuiltExePath!,
              maxLines: 2,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _windowsFlutterStepDetail({
    required String label,
    required String idleText,
  }) {
    if (_activeCommand == label) {
      return 'Odhad ${(_flutterStepEstimatedProgress * 100).round()} % • $_flutterStepElapsedText';
    }
    if (_windowsWorkspace.completedBuildSteps.contains(label)) {
      return 'Dokončené • 100 %';
    }
    return idleText;
  }

  double? _windowsFlutterStepProgress(String label) {
    if (_activeCommand == label) return _flutterStepEstimatedProgress;
    if (_windowsWorkspace.completedBuildSteps.contains(label)) return 1.0;
    return null;
  }

  Future<bool> _runWindowsFlutterCommand(
    List<String> arguments, {
    required String label,
  }) async {
    final project = _project;
    if (project == null) {
      _showError('Najprv načítaj Windows DEV projekt STAVBY PRO.');
      return false;
    }

    setState(() {
      _busy = true;
      _activeCommand = label;
    });
    _startFlutterStepProgress(label);
    _addLog('▶ flutter ${arguments.join(' ')}');
    final commandOutput = <String>[];

    try {
      final process = await Process.start(
        'flutter',
        arguments,
        workingDirectory: project.projectPath,
        runInShell: true,
      );

      final stdoutDone = process.stdout
          .transform(systemEncoding.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            commandOutput.add(line);
            _addLog(line);
          })
          .asFuture<void>();
      final stderrDone = process.stderr
          .transform(systemEncoding.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            commandOutput.add('CHYBA: $line');
            _addLog('CHYBA: $line');
          })
          .asFuture<void>();

      final exitCode = await process.exitCode;
      await Future.wait<void>(<Future<void>>[stdoutDone, stderrDone]);

      if (exitCode == 0) {
        _finishFlutterStepProgress(success: true);
        if (mounted) {
          setState(() => _windowsWorkspace.completedBuildSteps.add(label));
        }
        _addLog('✔ $label bol úspešne dokončený.');
        return true;
      }

      _finishFlutterStepProgress(success: false);
      _addLog('✖ $label zlyhal. Návratový kód: $exitCode.');
      await _showBuildFailureDialog(
        projectName: project.projectName,
        projectPath: project.projectPath,
        label: label,
        arguments: arguments,
        output: commandOutput,
        exitCode: exitCode,
      );
      return false;
    } catch (error, stackTrace) {
      _finishFlutterStepProgress(success: false);
      commandOutput.add('CHYBA: $error');
      _addLog('CHYBA: $error');
      await _showBuildFailureDialog(
        projectName: project.projectName,
        projectPath: project.projectPath,
        label: label,
        arguments: arguments,
        output: commandOutput,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeCommand = null;
        });
      }
    }
  }

  Future<File?> _findWindowsDevExe(String projectPath) async {
    final expectedPaths = <String>[
      path.join(projectPath, 'build', 'windows', 'x64', 'runner', 'Release', 'stavby_pro_dev.exe'),
      path.join(projectPath, 'build', 'windows', 'runner', 'Release', 'stavby_pro_dev.exe'),
      path.join(projectPath, 'build', 'windows', 'x64', 'runner', 'Debug', 'stavby_pro_dev.exe'),
    ];
    for (final candidate in expectedPaths) {
      final file = File(candidate);
      if (await file.exists()) return file;
    }

    final buildDir = Directory(path.join(projectPath, 'build', 'windows'));
    if (!await buildDir.exists()) return null;
    await for (final entity in buildDir.list(recursive: true, followLinks: false)) {
      if (entity is File &&
          path.basename(entity.path).toLowerCase() == 'stavby_pro_dev.exe') {
        return entity;
      }
    }
    return null;
  }

  Future<void> _verifyWindowsDevExe() async {
    final project = _project;
    if (project == null) return;
    setState(() {
      _busy = true;
      _activeCommand = 'Kontrola Windows EXE';
    });
    try {
      final exe = await _findWindowsDevExe(project.projectPath);
      if (exe == null) {
        throw const FileSystemException(
          'stavby_pro_dev.exe nebolo nájdené vo Windows build výstupe.',
        );
      }
      if (!mounted) return;
      setState(() {
        _windowsBuiltExePath = exe.path;
        _windowsWorkspace.completedBuildSteps.add('Kontrola Windows EXE');
      });
      _addLog('✔ Windows EXE nájdené: ${exe.path}');
    } catch (error) {
      _addLog('CHYBA: Kontrola Windows EXE zlyhala: $error');
      if (mounted) _showError('Kontrola Windows EXE zlyhala: $error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeCommand = null;
        });
      }
    }
  }


  Future<void> _buildWindowsReleaseStep() async {
    if (_project == null) {
      _showError('Najprv rozbaľ alebo vyber Windows DEV projekt.');
      return;
    }
    final ok = await _runWindowsFlutterCommand(
      <String>['build', 'windows', '--release'],
      label: 'Windows Release build',
    );
    if (ok) await _verifyWindowsDevExe();
  }


  Future<bool> _cleanWindowsEphemeralStep() async {
    final project = _project;
    if (project == null) return false;
    final ephemeralPath = path.join(
      project.projectPath,
      'windows',
      'flutter',
      'ephemeral',
    );
    if (mounted) {
      setState(() {
        _busy = true;
        _activeCommand = 'Vyčistenie Windows ephemeral';
      });
    }
    try {
      final ephemeralDirectory = Directory(ephemeralPath);
      _addLog('▶ Kontrolujem Windows Flutter ephemeral: $ephemeralPath');
      if (await ephemeralDirectory.exists()) {
        await ephemeralDirectory.delete(recursive: true);
        _addLog('✔ Windows Flutter ephemeral bol odstránený.');
      } else {
        _addLog('✔ Windows Flutter ephemeral už je čistý.');
      }
      if (mounted) {
        setState(() {
          _windowsWorkspace.completedBuildSteps.add('Vyčistenie Windows ephemeral');
        });
      }
      return true;
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Vyčistenie Windows Flutter ephemeral',
        projectPath: project.projectPath,
      );
      _addLog('✖ Vyčistenie Windows ephemeral zlyhalo: $error');
      if (mounted) _showError('Vyčistenie Windows ephemeral zlyhalo:\n\n$error');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeCommand = null;
        });
      }
    }
  }

  Future<bool> _verifyWindowsDevExeStep() async {
    final project = _project;
    if (project == null) return false;
    if (mounted) {
      setState(() {
        _busy = true;
        _activeCommand = 'Kontrola Windows EXE';
      });
    }
    try {
      final exe = await _findWindowsDevExe(project.projectPath);
      if (exe == null) {
        throw const FileSystemException(
          'stavby_pro_dev.exe nebolo nájdené vo Windows build výstupe.',
        );
      }
      if (mounted) {
        setState(() {
          _windowsBuiltExePath = exe.path;
          _windowsWorkspace.completedBuildSteps.add('Kontrola Windows EXE');
        });
      }
      _addLog('✔ Windows EXE nájdené: ${exe.path}');
      return true;
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Kontrola Windows EXE',
        projectPath: project.projectPath,
      );
      _addLog('✖ Kontrola Windows EXE zlyhala: $error');
      if (mounted) _showError('Kontrola Windows EXE zlyhala: $error');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeCommand = null;
        });
      }
    }
  }

  Future<bool> _launchWindowsDevExeStep({bool showSuccessMessage = true}) async {
    var exePath = _windowsBuiltExePath;
    if (exePath == null && _project != null) {
      exePath = (await _findWindowsDevExe(_project!.projectPath))?.path;
    }
    if (exePath == null || !await File(exePath).exists()) {
      if (mounted) _showError('Najprv vytvor Windows build a over stavby_pro_dev.exe.');
      return false;
    }

    if (mounted) {
      setState(() {
        _busy = true;
        _activeCommand = 'Spustenie Windows EXE';
        _windowsLaunchStatus =
            'Spúšťam stavby_pro_dev.exe a kontrolujem, či zostane bežať aspoň 5 sekúnd...';
        _windowsWorkspace.completedBuildSteps.remove('Spustenie Windows EXE');
      });
    }
    _addLog('▶ Spúšťam Windows EXE: $exePath');
    final stopwatch = Stopwatch()..start();

    try {
      final process = await Process.start(
        exePath,
        const <String>[],
        workingDirectory: path.dirname(exePath),
        runInShell: false,
      );
      _addLog('Windows proces spustený. PID: ${process.pid}');

      final stdoutSub = process.stdout
          .transform(systemEncoding.decoder)
          .transform(const LineSplitter())
          .listen((line) => _addLog('EXE: $line'));
      final stderrSub = process.stderr
          .transform(systemEncoding.decoder)
          .transform(const LineSplitter())
          .listen((line) => _addLog('EXE CHYBA: $line'));

      final earlyExit = await Future.any<Object?>(<Future<Object?>>[
        process.exitCode.then<Object?>((code) => code),
        Future<Object?>.delayed(const Duration(seconds: 5), () => null),
      ]);

      if (earlyExit is int) {
        stopwatch.stop();
        await stdoutSub.cancel();
        await stderrSub.cancel();
        final status =
            'EXE sa ukončilo príliš skoro po '
            '${stopwatch.elapsed.inMilliseconds / 1000.0}s '
            's EXIT CODE: $earlyExit.';
        if (mounted) setState(() => _windowsLaunchStatus = status);
        _addLog('✖ $status');
        if (mounted) {
          _showError(
            '$status\n\nBuild existuje, ale aplikácia sa reálne nespustila.',
          );
        }
        return false;
      }

      stopwatch.stop();
      if (mounted) {
        setState(() {
          _windowsWorkspace.completedBuildSteps.add('Spustenie Windows EXE');
          _windowsLaunchStatus =
              'stavby_pro_dev.exe beží dlhšie ako 5 sekúnd – test spustenia úspešný.';
        });
      }
      _addLog('✔ $_windowsLaunchStatus');
      if (showSuccessMessage && mounted) {
        _showSuccess('stavby_pro_dev.exe sa úspešne spustilo a zostalo bežať.');
      }
      return true;
    } catch (error, stackTrace) {
      stopwatch.stop();
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Spustenie Windows EXE',
        projectPath: _project?.projectPath,
      );
      if (mounted) {
        setState(() => _windowsLaunchStatus = 'Spustenie EXE zlyhalo: $error');
      }
      _addLog('✖ $_windowsLaunchStatus');
      if (mounted) _showError(_windowsLaunchStatus);
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeCommand = null;
        });
      }
    }
  }

  Future<void> _loadBuildHistory() async {
    if (mounted) setState(() => _buildHistoryLoading = true);
    try {
      final entries = await _buildHistoryService.load();
      if (mounted) setState(() => _buildHistory = entries);
    } catch (error) {
      _addLog('⚠ História buildov sa nepodarila načítať: $error');
    } finally {
      if (mounted) setState(() => _buildHistoryLoading = false);
    }
  }

  Future<void> _saveSuccessfulWindowsBuild(ProjectInfo project) async {
    final entry = BuildHistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      platform: 'Windows',
      version: project.version,
      build: project.releaseBuild,
      variant: project.releaseVariant.isEmpty ? 'NEURČENÉ' : project.releaseVariant,
      projectPath: project.projectPath,
      analyzeOk: _windowsWorkspace.completedBuildSteps.contains('Windows Flutter analyze'),
      buildOk: _windowsWorkspace.completedBuildSteps.contains('Windows Release build'),
      exePath: _windowsBuiltExePath,
      exportPath: _windowsExportedPath,
    );
    try {
      await _buildHistoryService.add(entry);
      await _loadBuildHistory();
      _addLog('✔ Build ${project.version}+${project.releaseBuild} bol uložený do histórie.');
    } catch (error) {
      _addLog('⚠ Build sa nepodarilo uložiť do histórie: $error');
    }
  }

  Future<void> _clearBuildHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vymazať históriu buildov?'),
        content: const Text('Táto operácia odstráni lokálnu históriu buildov Release Managera.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ZRUŠIŤ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('VYMAZAŤ')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _buildHistoryService.clear();
    await _loadBuildHistory();
    if (mounted) _showSuccess('História buildov bola vymazaná.');
  }

  Widget _buildBuildHistoryPanel() {
    final latest = _buildHistory.isEmpty ? null : _buildHistory.first;
    return RMSectionCard(
      title: 'HISTÓRIA WINDOWS BUILDOV',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const _ColorIcon(icon: Icons.history_rounded, color: Color(0xFF7E57C2)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      latest == null
                          ? 'Zatiaľ nie je uložený žiadny úspešný Windows build.'
                          : 'Posledný: ${latest.version} • Build ${latest.build} • ${latest.variant}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      latest == null
                          ? 'História sa doplní automaticky po úspešnom kompletnom Windows workspace builde.'
                          : '${latest.formattedDate} • ${latest.platform} • Analyze ${latest.analyzeOk ? 'OK' : 'CHYBA'} • Build ${latest.buildOk ? 'OK' : 'CHYBA'}',
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Obnoviť históriu',
                onPressed: _buildHistoryLoading ? null : _loadBuildHistory,
                icon: _buildHistoryLoading
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Vymazať históriu',
                onPressed: _buildHistory.isEmpty ? null : _clearBuildHistory,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          if (_buildHistory.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            ..._buildHistory.take(8).map((entry) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        entry.buildOk && entry.analyzeOk ? Icons.check_circle_rounded : Icons.error_rounded,
                        color: entry.buildOk && entry.analyzeOk ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('${entry.version} • Build ${entry.build} • ${entry.variant}',
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text('${entry.formattedDate} • ${entry.platform}'),
                            if (entry.exePath != null)
                              Text(entry.exePath!, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: 'Analyze: ${entry.analyzeOk ? 'OK' : 'CHYBA'}\nBuild: ${entry.buildOk ? 'OK' : 'CHYBA'}',
                        child: const Icon(Icons.info_outline_rounded),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Future<void> _runFullWindowsDevBuild() async {
    final project = _project;
    if (project == null) {
      _showError('Najprv rozbaľ alebo vyber Windows DEV projekt.');
      return;
    }

    setState(() {
      _windowsWorkspace.completedBuildSteps.clear();
      _windowsBuiltExePath = null;
      _windowsExportedPath = null;
      _windowsLaunchStatus = 'Čaká na zostavenie Windows aplikácie.';
    });
    _addLog('=== ZAČÍNA KOMPLETNÝ WINDOWS WORKSPACE BUILD ===');

    bool ok = await _checkWindowsEnvironment(showResult: false);
    if (!ok) {
      _addLog('=== WINDOWS BUILD ZASTAVENÝ: KONTROLA PROSTREDIA ===');
      return;
    }

    ok = await _runWindowsFlutterCommand(
      <String>['clean'],
      label: 'Windows Flutter clean',
    );
    if (!ok) {
      _addLog('=== WINDOWS BUILD ZASTAVENÝ: FLUTTER CLEAN ===');
      return;
    }

    ok = await _cleanWindowsEphemeralStep();
    if (!ok) {
      _addLog('=== WINDOWS BUILD ZASTAVENÝ: EPHEMERAL ===');
      return;
    }

    ok = await _runWindowsFlutterCommand(
      <String>['pub', 'get'],
      label: 'Windows Flutter pub get',
    );
    if (!ok) {
      _addLog('=== WINDOWS BUILD ZASTAVENÝ: PUB GET ===');
      return;
    }
    ok = await _runWindowsFlutterCommand(
      <String>['analyze'],
      label: 'Windows Flutter analyze',
    );
    if (!ok) {
      _addLog('=== WINDOWS BUILD ZASTAVENÝ: FLUTTER ANALYZE ===');
      return;
    }
    if (mounted) {
      setState(() => _windowsWorkspace.completedBuildSteps.add('Príprava Windows build'));
    }

    ok = await _runWindowsFlutterCommand(
      <String>['build', 'windows', '--release'],
      label: 'Windows Release build',
    );
    if (!ok) {
      _addLog('=== WINDOWS BUILD ZASTAVENÝ: BUILD WINDOWS ===');
      return;
    }

    ok = await _verifyWindowsDevExeStep();
    if (!ok) {
      _addLog('=== WINDOWS BUILD ZASTAVENÝ: KONTROLA EXE ===');
      return;
    }

    ok = await _launchWindowsDevExeStep(showSuccessMessage: false);
    if (!ok) {
      _addLog('=== WINDOWS BUILD ZASTAVENÝ: TEST EXE ===');
      return;
    }

    _addLog('=== KOMPLETNÝ WINDOWS DEV BUILD BOL ÚSPEŠNÝ ===');
    await _saveSuccessfulWindowsBuild(project);
    if (mounted) {
      _showSuccess(
        'Kompletný Windows DEV build je hotový. '
        'Kontrola prostredia, clean, ephemeral, pub get, analyze, build, kontrola EXE aj 5-sekundový test prešli úspešne.',
      );
    }
  }

  Future<void> _launchWindowsDevExe() async {
    await _launchWindowsDevExeStep();
  }

  Future<void> _exportWindowsDevRelease() async {
    final project = _project;
    var exePath = _windowsBuiltExePath;
    if (project == null) {
      _showError('Najprv načítaj Windows DEV projekt.');
      return;
    }
    exePath ??= (await _findWindowsDevExe(project.projectPath))?.path;
    if (exePath == null) {
      _showError('Najprv úspešne vytvor Windows build.');
      return;
    }

    var exportRoot = _windowsReleaseExportDirectory?.trim();
    if (exportRoot == null || exportRoot.isEmpty) {
      await _chooseWindowsReleaseExportDirectory();
      exportRoot = _windowsReleaseExportDirectory?.trim();
    }
    if (exportRoot == null || exportRoot.isEmpty) return;

    final sourceDirectory = Directory(path.dirname(exePath));
    final targetDirectory =
        Directory(path.join(exportRoot, project.releaseFileStem));

    setState(() {
      _busy = true;
      _activeCommand = 'Export Windows Release';
    });
    try {
      if (await targetDirectory.exists()) {
        await targetDirectory.delete(recursive: true);
      }
      await targetDirectory.create(recursive: true);

      await for (final entity in sourceDirectory.list(recursive: true, followLinks: false)) {
        final relative = path.relative(entity.path, from: sourceDirectory.path);
        final destination = path.join(targetDirectory.path, relative);
        if (entity is Directory) {
          await Directory(destination).create(recursive: true);
        } else if (entity is File) {
          await File(destination).parent.create(recursive: true);
          await entity.copy(destination);
        }
      }

      if (!mounted) return;
      setState(() {
        _windowsExportedPath = targetDirectory.path;
        _windowsWorkspace.completedBuildSteps.add('Export Windows Release');
      });
      _addLog('Windows Release exportovaný: ${targetDirectory.path}');
      _showSuccess('Windows Release bol úspešne exportovaný.');
    } catch (error, stackTrace) {
      await _writeCrashLog(
        error,
        stackTrace,
        step: 'Export Windows Release',
        projectPath: project.projectPath,
      );
      if (mounted) _showError('Export Windows Release zlyhal: $error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeCommand = null;
        });
      }
    }
  }

  Future<void> _runFullBuild() async {
    final steps = <({List<String> arguments, String label})>[
      (arguments: <String>['clean'], label: 'Flutter clean'),
      (arguments: <String>['pub', 'get'], label: 'Flutter pub get'),
      (arguments: <String>['analyze'], label: 'Flutter analyze'),
      (arguments: <String>['test'], label: 'Flutter test'),
      (
        arguments: <String>['build', 'apk', '--release'],
        label: 'Release APK build',
      ),
      (
        arguments: <String>['build', 'appbundle', '--release'],
        label: 'Release AAB build',
      ),
    ];

    _addLog('=== ZAČÍNA KOMPLETNÝ BUILD APK ===');
    for (final step in steps) {
      final success = await _runFlutterCommand(
        step.arguments,
        label: step.label,
      );
      if (!success) {
        _addLog('=== BUILD ZASTAVENÝ PRE CHYBU ===');
        return;
      }
    }
    _addLog('=== KOMPLETNÝ BUILD APK BOL ÚSPEŠNÝ ===');
    await _analyzeApk();
    await _analyzeAab();
    _showSuccess('Release APK a AAB boli úspešne vytvorené a analyzované.');
  }



  Future<void> _copyDirectoryRecursive(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false, followLinks: false)) {
      final targetPath = path.join(destination.path, path.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectoryRecursive(entity, Directory(targetPath));
      } else if (entity is File) {
        await entity.copy(targetPath);
      }
    }
  }

  Future<String> _fileSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<String?> _gitValue(String projectPath, List<String> arguments) async {
    try {
      final result = await Process.run('git', arguments, workingDirectory: projectPath, runInShell: true);
      if (result.exitCode == 0) return result.stdout.toString().trim();
    } catch (_) {}
    return null;
  }

  Future<void> _openReleaseWizardDirectory() async {
    final directory = _releaseWizardReleaseDirectory;
    if (directory == null || !Directory(directory).existsSync()) return;
    await Process.run('explorer.exe', <String>[directory], runInShell: true);
  }

  Future<bool> _createReleaseWizardPackage({
    required ProjectInfo project,
    required String version,
    required int build,
    required String destinationRoot,
    required StringBuffer report,
  }) async {
    try {
      final safeVersion = version.replaceAll('.', '_');
      final releaseRoot = Directory(path.join(destinationRoot, 'STAVBY_PRO_${safeVersion}_BUILD_$build'));
      if (await releaseRoot.exists()) await releaseRoot.delete(recursive: true);
      final windowsDir = Directory(path.join(releaseRoot.path, 'Windows'));
      final androidDir = Directory(path.join(releaseRoot.path, 'Android'));
      final updateDir = Directory(path.join(releaseRoot.path, 'Update'));
      final reportsDir = Directory(path.join(releaseRoot.path, 'Reports'));
      final symbolsDir = Directory(path.join(releaseRoot.path, 'Symbols'));
      for (final directory in <Directory>[windowsDir, androidDir, updateDir, reportsDir, symbolsDir]) {
        await directory.create(recursive: true);
      }

      final exePath = _windowsBuiltExePath;
      if (exePath != null) await _copyDirectoryRecursive(File(exePath).parent, windowsDir);
      if (_apkPath != null) await File(_apkPath!).copy(path.join(androidDir.path, path.basename(_apkPath!)));
      if (_aabPath != null) await File(_aabPath!).copy(path.join(androidDir.path, path.basename(_aabPath!)));

      final commit = await _gitValue(project.projectPath, <String>['rev-parse', '--short', 'HEAD']);
      final branch = await _gitValue(project.projectPath, <String>['branch', '--show-current']);
      final tag = await _gitValue(project.projectPath, <String>['describe', '--tags', '--exact-match', 'HEAD']);
      final now = DateTime.now();
      report
        ..writeln('Release priečinok: ${releaseRoot.path}')
        ..writeln('Git vetva: ${branch ?? 'nezistená'}')
        ..writeln('Git commit: ${commit ?? 'nezistený'}')
        ..writeln('Git tag: ${tag ?? 'bez tagu'}');

      final artifacts = <File>[];
      if (_windowsBuiltExePath != null) artifacts.add(File(_windowsBuiltExePath!));
      if (_apkPath != null) artifacts.add(File(_apkPath!));
      if (_aabPath != null) artifacts.add(File(_aabPath!));
      final rows = <String>[];
      for (final file in artifacts) {
        if (!await file.exists()) continue;
        final size = await file.length();
        final hash = await _fileSha256(file);
        rows.add('<tr><td>${path.basename(file.path)}</td><td>$size</td><td><code>$hash</code></td></tr>');
        report.writeln('${path.basename(file.path)} | $size B | SHA-256 $hash');
      }

      final html = '<!doctype html><html lang="sk"><head><meta charset="utf-8"><title>STAVBY PRO Release $version+$build</title>'
          '<style>body{font-family:Segoe UI,Arial,sans-serif;margin:36px;color:#172033}h1{color:#5b21b6}table{border-collapse:collapse;width:100%}th,td{border:1px solid #d7dce5;padding:10px;text-align:left}th{background:#f2efff}code{font-size:12px;word-break:break-all}.ok{color:#137333;font-weight:700}</style></head><body>'
          '<h1>STAVBY PRO Release Report</h1><p class="ok">Release úspešne pripravený</p>'
          '<p><b>Verzia:</b> $version+$build<br><b>Dátum:</b> ${now.toIso8601String()}<br><b>Git vetva:</b> ${branch ?? 'nezistená'}<br><b>Git commit:</b> ${commit ?? 'nezistený'}<br><b>Git tag:</b> ${tag ?? 'bez tagu'}</p>'
          '<h2>Výstupy</h2><table><tr><th>Súbor</th><th>Veľkosť (B)</th><th>SHA-256</th></tr>${rows.join()}</table></body></html>';
      await File(path.join(reportsDir.path, 'RELEASE_REPORT_${version}_BUILD_$build.html')).writeAsString(html, flush: true);
      await File(path.join(reportsDir.path, 'RELEASE_REPORT_${version}_BUILD_$build.txt')).writeAsString(report.toString(), flush: true);
      await File(path.join(updateDir.path, 'README.txt')).writeAsString('Priečinok pre aktualizačné balíky STAVBY PRO $version+$build.\n', flush: true);
      await File(path.join(symbolsDir.path, 'README.txt')).writeAsString('Priečinok pre symboly a diagnostické súbory buildu $build.\n', flush: true);

      if (mounted) setState(() => _releaseWizardReleaseDirectory = releaseRoot.path);
      _addLog('✔ Kompletný release balík vytvorený: ${releaseRoot.path}');
      return true;
    } catch (error, stackTrace) {
      report.writeln('CHYBA pri vytváraní release balíka: $error');
      await _writeCrashLog(error, stackTrace, step: 'Release Wizard 3.0 – balenie', projectPath: project.projectPath);
      _addLog('CHYBA: Release balík sa nepodarilo vytvoriť: $error');
      return false;
    }
  }

  Future<void> _runReleaseWizard3() async {
    final currentProject = _project;
    if (currentProject == null || _releaseWizardRunning) {
      if (currentProject == null) {
        _showError('Najprv otvor projekt STAVBY PRO.');
      }
      return;
    }

    final versionController = TextEditingController(text: currentProject.version);
    final buildController = TextEditingController(text: currentProject.build.toString());
    final configuredReleaseDestination = _windowsReleaseExportDirectory?.trim();
    final releaseDestination = configuredReleaseDestination == null || configuredReleaseDestination.isEmpty
        ? path.dirname(currentProject.projectPath)
        : configuredReleaseDestination;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: <Widget>[
            Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED)),
            SizedBox(width: 10),
            Text('Release Wizard 3.0'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Projekt: ${currentProject.projectName}'),
              Text('Cesta: ${currentProject.projectPath}'),
              const SizedBox(height: 16),
              TextField(
                controller: versionController,
                decoration: const InputDecoration(
                  labelText: 'Verzia',
                  hintText: 'napr. 3.6.94',
                  prefixIcon: Icon(Icons.new_releases_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: buildController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Flutter build',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sprievodca aktualizuje pubspec.yaml, vykoná všetky buildy a vytvorí kompletný release balík v adresároch Windows, Android, Update, Reports a Symbols. Pri prvej chybe sa bezpečne zastaví.',
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ZRUŠIŤ'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.rocket_launch_rounded),
            label: const Text('SPUSTIŤ WIZARD'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final newVersion = versionController.text.trim();
    final newBuild = int.tryParse(buildController.text.trim());
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(newVersion) || newBuild == null || newBuild <= 0) {
      _showError('Zadaj platnú verziu a build väčší ako nula.');
      return;
    }

    setState(() {
      _releaseWizardRunning = true;
      _releaseWizardStep = 0;
      _releaseWizardStatus = 'Spúšťam Release Wizard 3.0...';
      _releaseWizardReportPath = null;
      _releaseWizardReleaseDirectory = null;
      _releaseWizardCompletedSteps.clear();
    });
    final startedAt = DateTime.now();
    final report = StringBuffer()
      ..writeln('STAVBY PRO RELEASE WIZARD 3.0 – REPORT')
      ..writeln('=======================================')
      ..writeln('Release Manager: ${ReleaseManagerVersion.label}')
      ..writeln('Projekt: ${currentProject.projectPath}')
      ..writeln('Začiatok: ${startedAt.toIso8601String()}');

    Future<bool> step(String title, Future<bool> Function() action) async {
      if (!mounted) return false;
      setState(() {
        _releaseWizardStep += 1;
        _releaseWizardStatus = title;
      });
      _addLog('=== RELEASE WIZARD 3.0: $title ===');
      final ok = await action();
      report.writeln('${ok ? 'OK' : 'CHYBA'}: $title');
      if (ok && mounted) {
        setState(() => _releaseWizardCompletedSteps.add(title));
      }
      return ok;
    }

    var success = false;
    try {
      if (newVersion != currentProject.version || newBuild != currentProject.build) {
        await _pubspecService.updateVersion(
          project: currentProject,
          newVersion: newVersion,
          newBuild: newBuild,
        );
        final refreshed = await _pubspecService.readProject(currentProject.projectPath);
        if (mounted) setState(() => _project = refreshed);
        report.writeln('OK: Verzia aktualizovaná na $newVersion+$newBuild');
        _addLog('✔ Verzia projektu aktualizovaná na $newVersion+$newBuild.');
      } else {
        report.writeln('OK: Verzia zostala $newVersion+$newBuild');
      }

      if (!await step('Flutter clean', () => _runFlutterCommand(<String>['clean'], label: 'Flutter clean'))) return;
      if (!await step('Flutter pub get', () => _runFlutterCommand(<String>['pub', 'get'], label: 'Flutter pub get'))) return;
      if (!await step('Flutter analyze', () => _runFlutterCommand(<String>['analyze'], label: 'Flutter analyze'))) return;
      if (!await step('Flutter test', () => _runFlutterCommand(<String>['test'], label: 'Flutter test'))) return;
      if (!await step('Windows Release build', () => _runWindowsFlutterCommand(<String>['build', 'windows', '--release'], label: 'Windows Release build'))) return;
      await _verifyWindowsDevExe();
      if (_windowsBuiltExePath == null) return;
      if (!await step('Release APK build', () => _runFlutterCommand(<String>['build', 'apk', '--release'], label: 'Release APK build'))) return;
      await _analyzeApk();
      if (_apkPath == null || _apkSha256 == null) return;
      if (!await step('Release AAB build', () => _runFlutterCommand(<String>['build', 'appbundle', '--release'], label: 'Release AAB build'))) return;
      await _analyzeAab();
      if (_aabPath == null || _aabSha256 == null) return;
      if (!await step(
        'Vytvorenie release balíka',
        () => _createReleaseWizardPackage(
          project: _project ?? currentProject,
          version: newVersion,
          build: newBuild,
          destinationRoot: releaseDestination,
          report: report,
        ),
      )) {
        return;
      }
      success = true;
    } catch (error, stackTrace) {
      report.writeln('CHYBA: $error');
      await _writeCrashLog(error, stackTrace, step: 'Release Wizard 3.0', projectPath: currentProject.projectPath);
      if (mounted) _showError('Release Wizard 3.0 zlyhal: $error');
    } finally {
      final finishedAt = DateTime.now();
      report
        ..writeln('Koniec: ${finishedAt.toIso8601String()}')
        ..writeln('Výsledok: ${success ? 'ÚSPEŠNÝ' : 'NEÚSPEŠNÝ'}')
        ..writeln('Windows EXE: ${_windowsBuiltExePath ?? 'nevytvorené'}')
        ..writeln('APK: ${_apkPath ?? 'nevytvorené'}')
        ..writeln('AAB: ${_aabPath ?? 'nevytvorené'}');
      try {
        final reportFile = File(path.join(currentProject.projectPath, 'RELEASE_WIZARD_3_REPORT_${_diagnosticTimeStamp(finishedAt)}.txt'));
        await reportFile.writeAsString(report.toString(), flush: true);
        if (mounted) {
          setState(() => _releaseWizardReportPath = reportFile.path);
        }
      } catch (_) {}
      if (mounted) {
        setState(() {
          _releaseWizardRunning = false;
          _releaseWizardStatus = success
              ? 'Kompletný Windows a Android release balík bol vytvorený.'
              : 'Sprievodca sa zastavil pri neúspešnom kroku.';
        });
      }
      if (success && mounted) {
        _showSuccess('Release Wizard 3.0 úspešne vytvoril kompletný release balík.');
      }
    }
  }

  Future<void> _analyzeApk({bool silentIfMissing = false}) async {
    final project = _project;
    if (project == null) {
      _showError('Najprv vyber projekt STAVBY PRO.');
      return;
    }

    setState(() {
      _busy = true;
      _activeCommand = 'Analýza APK';
    });
    _addLog('Hľadám release APK...');

    try {
      final apk = await _findReleaseApk(project.projectPath);
      if (apk == null) {
        if (silentIfMissing) {
          _addLog('APK zatiaľ nebolo vytvorené. Po APK builde sa analyzuje automaticky.');
          return;
        }
        throw const FileSystemException(
          'Release APK nebolo nájdené. Najprv spusti BUILD APK.',
        );
      }

      final size = await apk.length();
      final digest = await sha256.bind(apk.openRead()).first;
      if (!mounted) return;
      setState(() {
        _apkPath = apk.path;
        _apkSizeBytes = size;
        _apkSha256 = digest.toString();
      });
      _addLog('APK nájdené: ${apk.path}');
      _addLog('Veľkosť APK: $size B (${_formatMb(size)} MB)');
      _addLog('SHA-256: $digest');
    } catch (error) {
      _addLog('CHYBA: Analýza APK zlyhala: $error');
      _showError('Analýza APK zlyhala: $error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeCommand = null;
        });
      }
    }
  }

  Future<File?> _findReleaseApk(String projectPath) async {
    final expected = File(
      path.join(
        projectPath,
        'build',
        'app',
        'outputs',
        'flutter-apk',
        'app-release.apk',
      ),
    );
    if (await expected.exists()) return expected;

    final outputs = Directory(path.join(projectPath, 'build', 'app', 'outputs'));
    if (!await outputs.exists()) return null;

    final files = <File>[];
    await for (final entity in outputs.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.apk')) {
        files.add(entity);
      }
    }
    if (files.isEmpty) return null;
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files.first;
  }


  Future<void> _analyzeAab({bool silentIfMissing = false}) async {
    final project = _project;
    if (project == null) {
      _showError('Najprv vyber projekt STAVBY PRO.');
      return;
    }
    setState(() { _busy = true; _activeCommand = 'Analýza AAB'; });
    try {
      final aab = await _findReleaseAab(project.projectPath);
      if (aab == null) {
        if (silentIfMissing) return;
        throw const FileSystemException('Release AAB nebolo nájdené. Najprv spusti BUILD AAB.');
      }
      final size = await aab.length();
      final digest = await sha256.bind(aab.openRead()).first;
      if (!mounted) return;
      setState(() { _aabPath = aab.path; _aabSizeBytes = size; _aabSha256 = digest.toString(); });
      _addLog('AAB nájdené: ${aab.path}');
      _addLog('Veľkosť AAB: $size B (${_formatMb(size)} MB)');
      _addLog('SHA-256 AAB: $digest');
    } catch (error) {
      _addLog('CHYBA: Analýza AAB zlyhala: $error');
      if (!silentIfMissing) _showError('Analýza AAB zlyhala: $error');
    } finally {
      if (mounted) setState(() { _busy = false; _activeCommand = null; });
    }
  }

  Future<File?> _findReleaseAab(String projectPath) async {
    final expected = File(path.join(projectPath, 'build', 'app', 'outputs', 'bundle', 'release', 'app-release.aab'));
    if (await expected.exists()) return expected;
    final outputs = Directory(path.join(projectPath, 'build', 'app', 'outputs'));
    if (!await outputs.exists()) return null;
    final files = <File>[];
    await for (final entity in outputs.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.aab')) files.add(entity);
    }
    if (files.isEmpty) return null;
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files.first;
  }

  String _formatMb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(2);

  Future<void> _copyApkData() async {
    final project = _project;
    final apkPath = _apkPath;
    final size = _apkSizeBytes;
    final hash = _apkSha256;
    if (project == null || apkPath == null || size == null || hash == null) {
      _showError('Najprv analyzuj vytvorené APK.');
      return;
    }

    final text = '''Version: ${project.version}
Build OTA: ${project.releaseBuild}
Build Flutter: ${project.build}
APK: ${path.basename(apkPath)}
Size: $size
SHA256: $hash''';
    await Clipboard.setData(ClipboardData(text: text));
    _addLog('Údaje APK boli skopírované do schránky.');
    _showSuccess('Údaje APK boli skopírované.');
  }




  Future<void> _exportAndroidRelease() async {
    final project = _project;
    final apkPath = _apkPath;
    if (project == null || apkPath == null || _apkSha256 == null) {
      _showError('Najprv vytvor a over Release APK.');
      return;
    }

    var exportDirectoryPath = _androidReleaseExportDirectory?.trim();
    if (exportDirectoryPath == null || exportDirectoryPath.isEmpty) {
      await _chooseAndroidReleaseExportDirectory();
      exportDirectoryPath = _androidReleaseExportDirectory?.trim();
    }
    if (exportDirectoryPath == null || exportDirectoryPath.isEmpty) {
      _showError('Najprv nastav samostatný priečinok pre Android APK Release.');
      return;
    }

    setState(() {
      _busy = true;
      _activeCommand = 'Export Android Release';
    });
    try {
      final outputDirectory = Directory(exportDirectoryPath);
      await outputDirectory.create(recursive: true);
      final fileName = '${project.releaseFileStem}.apk';
      final outputFile = File(path.join(outputDirectory.path, fileName));

      // Odstráň starý názov bez DEV/BETA/RC pre rovnakú verziu a build,
      // aby v exportnom priečinku nezostal mätúci súbor z predchádzajúcej verzie.
      final legacyFile = File(
        path.join(
          outputDirectory.path,
          'STAVBY_PRO_${project.version}_BUILD_${project.releaseBuild}.apk',
        ),
      );
      if (project.releaseVariant.isNotEmpty &&
          legacyFile.path != outputFile.path &&
          await legacyFile.exists()) {
        await legacyFile.delete();
        _addLog('Odstránený starý APK názov bez označenia vetvy: ${legacyFile.path}');
      }

      if (await outputFile.exists()) await outputFile.delete();
      await File(apkPath).copy(outputFile.path);
      _addLog(
        'Typ Android vydania: '
        '${project.releaseVariant.isEmpty ? 'RELEASE' : project.releaseVariant}',
      );

      if (_releaseNotesPreview != null && _releaseNotesPreview!.trim().isNotEmpty) {
        await File(path.join(outputDirectory.path, 'RELEASE_NOTES_${project.releaseFileStem}.md'))
            .writeAsString(_releaseNotesPreview!, flush: true);
      }
      if (_versionJsonPreview != null && _versionJsonPreview!.trim().isNotEmpty) {
        await File(path.join(outputDirectory.path, 'version.json'))
            .writeAsString(_versionJsonPreview!, flush: true);
      }

      if (!mounted) return;
      setState(() {
        _androidExportedApkPath = outputFile.path;
        _completedApkBuildSteps.add('Export Android Release');
      });
      _addLog('Android Release exportovaný: ${outputFile.path}');
      _showSuccess('Android Release bol úspešne exportovaný do: ${outputDirectory.path}');
    } catch (error, stackTrace) {
      await _writeCrashLog(error, stackTrace, step: 'Export Android Release', projectPath: project.projectPath);
      if (mounted) _showError('Export Android Release zlyhal: $error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeCommand = null;
        });
      }
    }
  }

  Future<void> _openApkFolder() async {
    final apkPath = _apkPath;
    if (apkPath == null) {
      _showError('Najprv vytvor alebo analyzuj release APK.');
      return;
    }

    try {
      await Process.run(
        'explorer.exe',
        <String>['/select,', apkPath],
        runInShell: true,
      );
      _addLog('Otváram priečinok s APK: ${path.dirname(apkPath)}');
    } catch (error) {
      _addLog('CHYBA: Priečinok s APK sa nepodarilo otvoriť: $error');
      _showError('Priečinok s APK sa nepodarilo otvoriť: $error');
    }
  }

  bool _isValidApkUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasAuthority) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    return uri.path.toLowerCase().endsWith('.apk');
  }

  Future<void> _pasteApkUrl() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final value = data?.text?.trim() ?? '';
    if (value.isEmpty) {
      _showError('Schránka neobsahuje text.');
      return;
    }
    setState(() {
      _apkUrlController.text = value;
      _apkUrlController.selection = TextSelection.collapsed(offset: value.length);
      _versionJsonPreview = null;
    });
    _addLog('URL APK bola vložená zo schránky.');
  }

  String _buildVersionJson() {
    final project = _project;
    final apkPath = _apkPath;
    final size = _apkSizeBytes;
    final hash = _apkSha256;
    final apkUrl = _apkUrlController.text.trim();

    if (project == null || apkPath == null || size == null || hash == null) {
      throw const FormatException('Najprv nájdi a analyzuj release APK.');
    }
    if (apkUrl.isNotEmpty && !_isValidApkUrl(apkUrl)) {
      throw const FormatException(
        'URL musí byť úplná HTTP/HTTPS adresa a musí smerovať na súbor .apk.',
      );
    }

    final data = <String, Object>{
      'version': project.version,
      'build': project.releaseBuild,
      'apkUrl': apkUrl,
      'sizeBytes': size,
      'sha256': hash,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  void _generateVersionJsonPreview() {
    try {
      final jsonText = _buildVersionJson();
      setState(() => _versionJsonPreview = jsonText);
      _addLog('Náhľad version.json bol vygenerovaný a validovaný.');
      _showSuccess('version.json je pripravený.');
    } on FormatException catch (error) {
      _showError(error.message);
      _addLog('CHYBA: ${error.message}');
    }
  }

  Future<void> _saveVersionJson() async {
    try {
      final jsonText = _buildVersionJson();
      final project = _project!;
      final outputPath = await FilePicker.saveFile(
        dialogTitle: 'Uložiť version.json',
        fileName: 'version.json',
        initialDirectory: project.projectPath,
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
      );
      if (outputPath == null) {
        _addLog('Uloženie version.json bolo zrušené.');
        return;
      }
      final normalizedPath = outputPath.toLowerCase().endsWith('.json')
          ? outputPath
          : '$outputPath.json';
      await File(normalizedPath).writeAsString('$jsonText\n', flush: true);
      if (!mounted) return;
      setState(() => _versionJsonPreview = jsonText);
      _addLog('version.json uložený: $normalizedPath');
      _showSuccess('version.json bol úspešne uložený.');
    } on FormatException catch (error) {
      _showError(error.message);
      _addLog('CHYBA: ${error.message}');
    } catch (error) {
      _showError('Uloženie version.json zlyhalo: $error');
      _addLog('CHYBA: $error');
    }
  }

  Future<void> _copyVersionJson() async {
    try {
      final jsonText = _buildVersionJson();
      await Clipboard.setData(ClipboardData(text: jsonText));
      if (!mounted) return;
      setState(() => _versionJsonPreview = jsonText);
      _addLog('Obsah version.json bol skopírovaný do schránky.');
      _showSuccess('JSON bol skopírovaný.');
    } on FormatException catch (error) {
      _showError(error.message);
      _addLog('CHYBA: ${error.message}');
    }
  }


  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  List<String> _noteItems(String text) {
    return text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => line.replaceFirst(RegExp(r'^[-•*]\s*'), ''))
        .toList();
  }

  String _buildReleaseNotes() {
    final project = _project;
    if (project == null) {
      throw const FormatException('Najprv vyber projekt STAVBY PRO.');
    }
    final news = _noteItems(_newsController.text);
    final fixes = _noteItems(_fixesController.text);
    if (news.isEmpty && fixes.isEmpty) {
      throw const FormatException('Zadaj aspoň jednu novinku alebo opravu.');
    }

    final buffer = StringBuffer()
      ..writeln('# STAVBY PRO ${project.version}')
      ..writeln()
      ..writeln('Dátum vydania: ${_formatDate(DateTime.now())}');
    if (news.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Novinky')
        ..writeln();
      for (final item in news) {
        buffer.writeln('- $item');
      }
    }
    if (fixes.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Opravy')
        ..writeln();
      for (final item in fixes) {
        buffer.writeln('- $item');
      }
    }
    return buffer.toString().trimRight();
  }

  void _generateReleaseNotesPreview() {
    try {
      final markdown = _buildReleaseNotes();
      setState(() => _releaseNotesPreview = markdown);
      _addLog('Náhľad RELEASE_NOTES.md bol vygenerovaný.');
      _showSuccess('Release Notes sú pripravené.');
    } on FormatException catch (error) {
      _showError(error.message);
      _addLog('CHYBA: ${error.message}');
    }
  }

  Future<void> _saveReleaseNotes() async {
    try {
      final markdown = _buildReleaseNotes();
      final project = _project!;
      final outputPath = await FilePicker.saveFile(
        dialogTitle: 'Uložiť RELEASE_NOTES.md',
        fileName: 'RELEASE_NOTES.md',
        initialDirectory: project.projectPath,
        type: FileType.custom,
        allowedExtensions: const <String>['md'],
      );
      if (outputPath == null) {
        _addLog('Uloženie RELEASE_NOTES.md bolo zrušené.');
        return;
      }
      final normalizedPath = outputPath.toLowerCase().endsWith('.md')
          ? outputPath
          : '$outputPath.md';
      await File(normalizedPath).writeAsString('$markdown\n', flush: true);
      if (!mounted) return;
      setState(() => _releaseNotesPreview = markdown);
      _addLog('RELEASE_NOTES.md uložený: $normalizedPath');
      _showSuccess('RELEASE_NOTES.md bol úspešne uložený.');
    } on FormatException catch (error) {
      _showError(error.message);
      _addLog('CHYBA: ${error.message}');
    } catch (error) {
      _showError('Uloženie Release Notes zlyhalo: $error');
      _addLog('CHYBA: $error');
    }
  }

  Future<void> _copyReleaseNotes() async {
    try {
      final markdown = _buildReleaseNotes();
      await Clipboard.setData(ClipboardData(text: markdown));
      if (!mounted) return;
      setState(() => _releaseNotesPreview = markdown);
      _addLog('Release Notes boli skopírované do schránky.');
      _showSuccess('Release Notes boli skopírované.');
    } on FormatException catch (error) {
      _showError(error.message);
      _addLog('CHYBA: ${error.message}');
    }
  }


  String _buildGithubRelease() {
    final project = _project;
    final size = _apkSizeBytes;
    final hash = _apkSha256;
    if (project == null) {
      throw const FormatException('Najprv vyber projekt STAVBY PRO.');
    }
    if (size == null || hash == null) {
      throw const FormatException('Najprv nájdi a analyzuj APK.');
    }

    final news = _noteItems(_newsController.text);
    final fixes = _noteItems(_fixesController.text);
    if (news.isEmpty && fixes.isEmpty) {
      throw const FormatException('Zadaj aspoň jednu novinku alebo opravu.');
    }

    final releaseApkName =
        'STAVBY_PRO_${project.version}_BUILD_${project.releaseBuild}.apk';
    final url = _apkUrlController.text.trim();
    final buffer = StringBuffer()
      ..writeln('STAVBY PRO ${project.version}')
      ..writeln()
      ..writeln('Dátum vydania: ${_formatDate(DateTime.now())}');

    if (news.isNotEmpty) {
      buffer..writeln()..writeln('Novinky');
      for (final item in news) {
        buffer.writeln('- $item');
      }
    }
    if (fixes.isNotEmpty) {
      buffer..writeln()..writeln('Opravy');
      for (final item in fixes) {
        buffer.writeln('- $item');
      }
    }

    buffer
      ..writeln()
      ..writeln('APK:')
      ..writeln(releaseApkName)
      ..writeln()
      ..writeln('Build OTA: ${project.releaseBuild}')
      ..writeln('Build Flutter: ${project.build}')
      ..writeln()
      ..writeln('Veľkosť:')
      ..writeln('$size B (${_formatMb(size)} MB)')
      ..writeln()
      ..writeln('SHA-256:')
      ..writeln(hash);

    if (url.isNotEmpty) {
      if (!_isValidApkUrl(url)) {
        throw const FormatException('URL APK nie je platná.');
      }
      buffer..writeln()..writeln('GitHub URL:')..writeln(url);
    }
    return buffer.toString().trimRight();
  }

  void _generateGithubReleasePreview() {
    try {
      final text = _buildGithubRelease();
      setState(() => _githubReleasePreview = text);
      _addLog('Náhľad GITHUB_RELEASE.txt bol vygenerovaný.');
      _showSuccess('GitHub Release text je pripravený.');
    } on FormatException catch (error) {
      _showError(error.message);
      _addLog('CHYBA: ${error.message}');
    }
  }

  Future<void> _saveGithubRelease() async {
    try {
      final text = _buildGithubRelease();
      final project = _project!;
      final outputPath = await FilePicker.saveFile(
        dialogTitle: 'Uložiť GITHUB_RELEASE.txt',
        fileName: 'GITHUB_RELEASE.txt',
        initialDirectory: project.projectPath,
        type: FileType.custom,
        allowedExtensions: const <String>['txt'],
      );
      if (outputPath == null) {
        _addLog('Uloženie GITHUB_RELEASE.txt bolo zrušené.');
        return;
      }
      final normalizedPath = outputPath.toLowerCase().endsWith('.txt')
          ? outputPath
          : '$outputPath.txt';
      await File(normalizedPath).writeAsString('$text\n', flush: true);
      if (!mounted) return;
      setState(() => _githubReleasePreview = text);
      _addLog('GITHUB_RELEASE.txt uložený: $normalizedPath');
      _showSuccess('GITHUB_RELEASE.txt bol úspešne uložený.');
    } on FormatException catch (error) {
      _showError(error.message);
      _addLog('CHYBA: ${error.message}');
    } catch (error) {
      _showError('Uloženie GitHub Release textu zlyhalo: $error');
      _addLog('CHYBA: $error');
    }
  }

  Future<void> _copyGithubRelease() async {
    try {
      final text = _buildGithubRelease();
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      setState(() => _githubReleasePreview = text);
      _addLog('GitHub Release text bol skopírovaný do schránky.');
      _showSuccess('GitHub Release text bol skopírovaný.');
    } on FormatException catch (error) {
      _showError(error.message);
      _addLog('CHYBA: ${error.message}');
    }
  }


  String _powershellLiteral(String value) => value.replaceAll("'", "''");

  void _showError(String message) {
    if (!mounted) return;
    _showCompactNotification(
      title: 'Chyba',
      message: message,
      icon: Icons.error_outline_rounded,
      color: const Color(0xFFEF4444),
      duration: const Duration(seconds: 7),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    _showCompactNotification(
      title: 'Hotovo',
      message: message,
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF22C55E),
    );
  }

  void _showCompactNotification({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width >= 720 ? 460.0 : width - 32;
    final leftMargin = width >= 720 ? width - cardWidth - 22 : 16.0;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration,
          elevation: 10,
          backgroundColor: const Color(0xFF172027),
          margin: EdgeInsets.fromLTRB(leftMargin, 0, width >= 720 ? 22 : 16, 22),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withValues(alpha: 0.55)),
          ),
          showCloseIcon: true,
          closeIconColor: Colors.white70,
          content: Container(
            constraints: const BoxConstraints(minHeight: 66),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border(left: BorderSide(color: color, width: 5)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.25,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }


  Future<void> _showReleaseHistoryDialog() async {
    await _loadReleaseHistory();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('História buildov'),
        content: SizedBox(
          width: 620,
          child: _releaseHistory.isEmpty
              ? const Text('História zatiaľ neobsahuje žiadne záznamy.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _releaseHistory.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _releaseHistory[_releaseHistory.length - 1 - index];
                    final version = (item['version'] ?? '—').toString();
                    final build = (item['build'] ?? '—').toString();
                    final date = (item['date'] ?? item['timestamp'] ?? '').toString();
                    return ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: Text('v$version • Build $build'),
                      subtitle: date.isEmpty ? null : Text(date),
                    );
                  },
                ),
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ZAVRIEŤ'),
          ),
        ],
      ),
    );
  }



  Future<Directory> _resolveDevelopmentZipRoot(Directory extractionDirectory) async {
    final directPubspec = File(path.join(extractionDirectory.path, 'pubspec.yaml'));
    if (await directPubspec.exists()) return extractionDirectory;

    final children = await extractionDirectory.list(followLinks: false).toList();
    final directories = children.whereType<Directory>().toList();
    if (directories.length == 1) {
      final nestedPubspec = File(path.join(directories.single.path, 'pubspec.yaml'));
      if (await nestedPubspec.exists()) return directories.single;
    }

    await for (final entity in extractionDirectory.list(recursive: true, followLinks: false)) {
      if (entity is File && path.basename(entity.path).toLowerCase() == 'pubspec.yaml') {
        final relative = path.relative(entity.parent.path, from: extractionDirectory.path);
        if (path.split(relative).length <= 2) return entity.parent;
      }
    }
    throw const FormatException('ZIP neobsahuje platný Flutter projekt s pubspec.yaml.');
  }

  bool _bytesEqual(List<int> left, List<int> right) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  Future<String> _readProjectVersionLabel(Directory projectRoot) async {
    final pubspec = File(path.join(projectRoot.path, 'pubspec.yaml'));
    final text = await pubspec.readAsString();
    final match = RegExp(r'^version:\s*([^\s]+)\s*$', multiLine: true).firstMatch(text);
    return match?.group(1) ?? 'nezistená verzia';
  }

  Future<void> _synchronizeDevelopmentZip() async {
    if (_workspaceSyncRunning) return;
    final workspacePath = _gitWorkspacePath;
    if (workspacePath == null || workspacePath.trim().isEmpty) {
      _showError('Najprv vyber pracovný Git projekt.');
      return;
    }
    final workspace = Directory(workspacePath);
    if (!await workspace.exists() || !await Directory(path.join(workspace.path, '.git')).exists()) {
      _showError('Vybraný pracovný priečinok nie je platný Git repozitár.');
      return;
    }

    final picked = await FilePicker.pickFiles(
      dialogTitle: 'Vyber vývojový ZIP projektu',
      type: FileType.custom,
      allowedExtensions: const <String>['zip'],
      allowMultiple: false,
      lockParentWindow: true,
    );
    final zipPath = picked?.files.single.path;
    if (zipPath == null || zipPath.trim().isEmpty) return;
    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      _showError('Vybraný ZIP súbor neexistuje.');
      return;
    }

    setState(() => _workspaceSyncRunning = true);
    Directory? tempRoot;
    Directory? backupStage;
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
      tempRoot = await Directory.systemTemp.createTemp('stavby_pro_workspace_sync_');
      final extracted = Directory(path.join(tempRoot.path, 'extracted'));
      await extracted.create(recursive: true);

      _addLog('=== WORKSPACE SYNC ===');
      _addLog('ZIP: ${zipFile.path}');
      _addLog('Workspace: ${workspace.path}');
      final expand = await Process.run(
        'powershell.exe',
        <String>[
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          "Expand-Archive -LiteralPath '${_powershellLiteral(zipFile.path)}' -DestinationPath '${_powershellLiteral(extracted.path)}' -Force",
        ],
        runInShell: false,
      );
      if (expand.exitCode != 0) {
        throw StateError('ZIP sa nepodarilo rozbaliť: ${expand.stderr}');
      }

      final sourceRoot = await _resolveDevelopmentZipRoot(extracted);
      final sourceVersion = await _readProjectVersionLabel(sourceRoot);
      final workspaceVersion = await _readProjectVersionLabel(workspace);
      final sourceGit = Directory(path.join(sourceRoot.path, '.git'));
      if (await sourceGit.exists()) {
        throw const FormatException('Vývojový ZIP nesmie obsahovať priečinok .git.');
      }

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(children: <Widget>[
            Icon(Icons.sync_rounded, color: Color(0xFF1565C0)),
            SizedBox(width: 10),
            Text('Synchronizovať vývojový ZIP'),
          ]),
          content: SizedBox(
            width: 620,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Zdroj: ${zipFile.path}', maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text('ZIP verzia: $sourceVersion'),
                Text('Aktuálny workspace: $workspaceVersion'),
                const SizedBox(height: 8),
                Text('Cieľ: ${workspace.path}', maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 14),
                const Text(
                  'Pred synchronizáciou sa vytvorí automatická záloha. Workspace sa potom nahradí čistým obsahom ZIP-u. Zachované zostanú iba .git, .gitignore a .release_manager.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('ZRUŠIŤ')),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.sync_rounded),
              label: const Text('ZÁLOHOVAŤ A SYNCHRONIZOVAŤ'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      final backupDirectory = Directory(path.join(workspace.parent.path, 'Backups'));
      await backupDirectory.create(recursive: true);
      backupStage = Directory(path.join(tempRoot.path, 'backup_stage'));
      await backupStage.create(recursive: true);

      final backupCopy = await Process.run(
        'robocopy.exe',
        <String>[
          workspace.path,
          backupStage.path,
          '/E', '/R:1', '/W:1', '/NFL', '/NDL', '/NJH', '/NJS', '/NP',
          '/XD', '.git', '.dart_tool', 'build', '.release_manager',
        ],
        runInShell: false,
      );
      if (backupCopy.exitCode >= 8) {
        throw StateError('Záloha workspace zlyhala (robocopy ${backupCopy.exitCode}).');
      }
      final backupZip = File(path.join(backupDirectory.path, 'Workspace_Backup_$timestamp.zip'));
      final compress = await Process.run(
        'powershell.exe',
        <String>[
          '-NoProfile', '-NonInteractive', '-Command',
          "Compress-Archive -Path '${_powershellLiteral(path.join(backupStage.path, '*'))}' -DestinationPath '${_powershellLiteral(backupZip.path)}' -CompressionLevel Optimal -Force",
        ],
        runInShell: false,
      );
      if (compress.exitCode != 0 || !await backupZip.exists()) {
        throw StateError('ZIP záloha sa nepodarila vytvoriť: ${compress.stderr}');
      }
      _addLog('Záloha: ${backupZip.path}');

      // Vytvor čistý workspace. Starý zdrojový strom sa nesmie miešať s
      // novým ZIP-om, preto sa zachovajú iba Git metadáta a nastavenia RM.
      const preservedTopLevel = <String>{'.git', '.gitignore', '.release_manager'};
      await for (final entity in workspace.list(followLinks: false)) {
        final name = path.basename(entity.path);
        if (preservedTopLevel.contains(name)) continue;
        try {
          if (entity is Directory) {
            await entity.delete(recursive: true);
          } else {
            await entity.delete();
          }
          _addLog('Workspace Sync: odstránené staré dáta: $name');
        } catch (error) {
          throw StateError('Nepodarilo sa odstrániť starú položku $name: $error');
        }
      }

      final sync = await Process.run(
        'robocopy.exe',
        <String>[
          sourceRoot.path,
          workspace.path,
          '/E', '/COPY:DAT', '/DCOPY:DAT', '/R:2', '/W:1',
          '/NFL', '/NDL', '/NJH', '/NJS', '/NP',
          '/XD', '.git', '.release_manager',
          '/XF', '.gitignore',
        ],
        runInShell: false,
      );
      if (sync.exitCode >= 8) {
        throw StateError('Synchronizácia zlyhala (robocopy ${sync.exitCode}).');
      }

      // Kritické súbory skopíruj ešte raz priamo cez Dart. Tým sa odstráni
      // závislosť od zvláštností robocopy pri časových pečiatkach a atribútoch.
      for (final relative in <String>[
        'pubspec.yaml',
        path.join('lib', 'features', 'about', 'version_service.dart'),
      ]) {
        final sourceFile = File(path.join(sourceRoot.path, relative));
        if (!await sourceFile.exists()) continue;
        final targetFile = File(path.join(workspace.path, relative));
        await targetFile.parent.create(recursive: true);
        await sourceFile.copy(targetFile.path);
      }

      final sourcePubspec = File(path.join(sourceRoot.path, 'pubspec.yaml'));
      final workspacePubspec = File(path.join(workspace.path, 'pubspec.yaml'));
      if (!await workspacePubspec.exists()) {
        throw StateError('Po synchronizácii v workspace chýba pubspec.yaml.');
      }
      final sourcePubspecBytes = await sourcePubspec.readAsBytes();
      final workspacePubspecBytes = await workspacePubspec.readAsBytes();
      if (!_bytesEqual(sourcePubspecBytes, workspacePubspecBytes)) {
        throw StateError('pubspec.yaml vo workspace nie je identický so súborom zo ZIP-u.');
      }

      // Over, že sa do workspace naozaj preniesla identita vybraného ZIP-u.
      // Bez tejto kontroly by sa mohol zostaviť starší build a následne dostať
      // nesprávny názov reportu, exportného ZIP-u, Git commitu alebo tagu.
      final synchronizedVersion = await _readProjectVersionLabel(workspace);
      if (synchronizedVersion != sourceVersion) {
        throw StateError(
          'Synchronizácia verzie zlyhala. ZIP obsahuje $sourceVersion, '
          'ale workspace po synchronizácii obsahuje $synchronizedVersion.',
        );
      }
      final synchronizedIdentity = await _readGitBuildIdentity(workspace.path);
      if (synchronizedIdentity == null) {
        throw StateError(
          'Po synchronizácii sa nepodarilo načítať verziu a build z pubspec.yaml.',
        );
      }
      _addLog(
        'Overená identita workspace: ${synchronizedIdentity.version}+'
        '${synchronizedIdentity.build} ${synchronizedIdentity.stage.toUpperCase()}.',
      );

      final synchronizedProject = await _pubspecService.readProject(workspace.path);
      if (synchronizedProject.version != synchronizedIdentity.version ||
          synchronizedProject.releaseBuild != synchronizedIdentity.build) {
        throw StateError(
          'PubspecService po synchronizácii vrátil inú identitu: '
          '${synchronizedProject.version}+${synchronizedProject.releaseBuild}, '
          'očakávané ${synchronizedIdentity.version}+${synchronizedIdentity.build}.',
        );
      }

      if (mounted) {
        setState(() {
          _project = synchronizedProject;
          _projectIdentitySnapshot = synchronizedIdentity;
          _projectIdentityLoading = false;
        });
      }
      _addLog(
        'Dashboard projekt obnovený po synchronizácii: '
        '${synchronizedProject.version}+${synchronizedProject.releaseBuild}.',
      );

      // Nový vývojový ZIP mení zdrojový kód. Všetky odvodené Flutter
      // artefakty a stav pokračovania preto musia byť zneplatnené, inak by
      // sa mohlo pokračovať od analyze nad starým package_config alebo
      // spustiť EXE z predchádzajúceho buildu.
      for (final relative in <String>[
        '.dart_tool',
        '.flutter-plugins',
        '.flutter-plugins-dependencies',
        'build',
      ]) {
        final entityPath = path.join(workspace.path, relative);
        final type = FileSystemEntity.typeSync(entityPath);
        if (type == FileSystemEntityType.directory) {
          await Directory(entityPath).delete(recursive: true);
          _addLog('Po synchronizácii odstránený odvodený priečinok: $relative');
        } else if (type == FileSystemEntityType.file) {
          await File(entityPath).delete();
          _addLog('Po synchronizácii odstránený odvodený súbor: $relative');
        }
      }

      if (mounted) {
        setState(() {
          _oneClickBuildResumeIndex = 0;
          _oneClickBuildCompletedSteps = 0;
          _oneClickBuildCurrentStep = 'Čaká';
          _oneClickBuildFailedLabel = null;
          _oneClickBuildFailedArguments = const <String>[];
          _oneClickBuildFailedOutput = const <String>[];
          _oneClickBuildFailedExitCode = null;
          _oneClickBuildFailedError = null;
          _oneClickBuildFailedStackTrace = null;
          _windowsBuiltExePath = null;
          _windowsExportedPath = null;
        });
      }
      _addLog('One Click Build bol po synchronizácii resetovaný. Ďalší build začne od flutter clean.');

      await _rememberGitWorkspace(workspace.path);
      await _refreshGitWorkspace();
      final refreshedIdentity = await _loadProjectIdentity(workspace.path);
      if (refreshedIdentity == null ||
          refreshedIdentity.version != synchronizedIdentity.version ||
          refreshedIdentity.build != synchronizedIdentity.build) {
        throw StateError(
          'ProjectVersionProvider po synchronizácii nevrátil očakávanú identitu '
          '${synchronizedIdentity.version}+${synchronizedIdentity.build}.',
        );
      }
      final changed = _gitWorkspaceStatus?.changedFiles.length ?? 0;
      _addLog('Workspace bol synchronizovaný. Git eviduje $changed zmien.');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(children: <Widget>[
            Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
            SizedBox(width: 10),
            Text('Workspace je aktualizovaný'),
          ]),
          content: Text(
            'Verzia zo ZIP: $sourceVersion\nGit zmeny: $changed\n\nZáloha: ${backupZip.path}',
          ),
          actions: <Widget>[
            TextButton(onPressed: () => _openDirectory(backupDirectory.path), child: const Text('OTVORIŤ ZÁLOHY')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('HOTOVO')),
          ],
        ),
      );
    } catch (error, stackTrace) {
      _addLog('Workspace Sync zlyhal: $error');
      await _writeCrashLog(error, stackTrace, step: 'Workspace Sync', projectPath: workspace.path);
      if (mounted) _showError('Workspace sa nepodarilo synchronizovať: $error');
    } finally {
      if (tempRoot != null && await tempRoot.exists()) {
        try { await tempRoot.delete(recursive: true); } catch (_) {}
      }
      if (mounted) setState(() => _workspaceSyncRunning = false);
    }
  }


  Future<bool> _runWorkspaceFlutterStep(
    String workspace,
    List<String> arguments,
    String label,
  ) async {
    if (mounted) {
      setState(() => _oneClickBuildCurrentStep = label);
    }
    _addLog('▶ flutter ${arguments.join(' ')}');
    final output = <String>[];
    try {
      final process = await Process.start(
        'flutter',
        arguments,
        workingDirectory: workspace,
        runInShell: true,
      );
      final stdoutDone = process.stdout
          .transform(systemEncoding.decoder)
          .transform(const LineSplitter())
          .listen((line) { output.add(line); _addLog(line); })
          .asFuture<void>();
      final stderrDone = process.stderr
          .transform(systemEncoding.decoder)
          .transform(const LineSplitter())
          .listen((line) { output.add(line); _addLog('CHYBA: $line'); })
          .asFuture<void>();
      final exitCode = await process.exitCode;
      await Future.wait<void>(<Future<void>>[stdoutDone, stderrDone]);
      final accepted = label == 'Flutter analyze'
          ? _acceptAnalyzeResult(exitCode: exitCode, output: output)
          : exitCode == 0;
      if (!accepted) {
        _oneClickBuildFailedLabel = label;
        _oneClickBuildFailedArguments = List<String>.unmodifiable(arguments);
        _oneClickBuildFailedOutput = List<String>.unmodifiable(output);
        _oneClickBuildFailedExitCode = exitCode;
        _oneClickBuildFailedError = null;
        _oneClickBuildFailedStackTrace = null;
        _addLog('✖ $label zlyhal. Návratový kód: $exitCode.');
        return false;
      }
      _addLog(exitCode == 0 ? '✔ $label bol úspešne dokončený.' : '⚠ $label obsahuje iba upozornenia.');
      if (mounted) {
        setState(() => _oneClickBuildCompletedSteps++);
      }
      return true;
    } catch (error, stackTrace) {
      _oneClickBuildFailedLabel = label;
      _oneClickBuildFailedArguments = List<String>.unmodifiable(arguments);
      _oneClickBuildFailedOutput = List<String>.unmodifiable(output);
      _oneClickBuildFailedExitCode = null;
      _oneClickBuildFailedError = error;
      _oneClickBuildFailedStackTrace = stackTrace;
      _addLog('✖ $label sa nepodarilo spustiť: $error');
      await _writeCrashLog(error, stackTrace, step: label, projectPath: workspace);
      return false;
    }
  }


  Future<File> _createOneClickReleaseZip(String projectPath) async {
    final releaseDirectory = Directory(
      path.join(projectPath, 'build', 'windows', 'x64', 'runner', 'Release'),
    );
    if (!await releaseDirectory.exists()) {
      throw StateError('Windows Release priečinok neexistuje: ${releaseDirectory.path}');
    }

    final identity = await _readGitBuildIdentity(projectPath);
    final version = identity?.version ?? 'UNKNOWN';
    final build = identity?.build ?? 0;
    final stage = (identity?.stage ?? 'DEV')
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final projectName = path.basename(projectPath).toUpperCase();

    var exportRoot = _windowsReleaseExportDirectory?.trim();
    if (exportRoot == null || exportRoot.isEmpty) {
      exportRoot = path.join(projectPath, 'Export Release');
    }
    final exportDirectory = Directory(exportRoot);
    await exportDirectory.create(recursive: true);

    final zipFile = File(path.join(
      exportDirectory.path,
      '${projectName}_${version}_${stage.isEmpty ? 'DEV' : stage}_BUILD_${build}_WINDOWS_RELEASE.zip',
    ));
    if (await zipFile.exists()) await zipFile.delete();

    final escapedSource = releaseDirectory.path.replaceAll("'", "''");
    final escapedDestination = zipFile.path.replaceAll("'", "''");
    final result = await Process.run(
      'powershell.exe',
      <String>[
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        "Compress-Archive -Path '$escapedSource\\*' -DestinationPath '$escapedDestination' -CompressionLevel Optimal -Force",
      ],
      workingDirectory: projectPath,
      runInShell: false,
    );
    if (result.exitCode != 0 || !await zipFile.exists()) {
      throw StateError('Export Release ZIP sa nepodarilo vytvoriť: ${result.stderr}');
    }
    _addLog('Export Release ZIP bol vytvorený: ${zipFile.path}');
    return zipFile;
  }

  Future<void> _selectFileInExplorer(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      _showError('Súbor neexistuje: $filePath');
      return;
    }
    await Process.start('explorer.exe', <String>['/select,', file.path], runInShell: false);
  }

  Future<void> _launchOneClickWindowsBuild(String projectPath) async {
    final releaseDirectory = Directory(
      path.join(projectPath, 'build', 'windows', 'x64', 'runner', 'Release'),
    );
    if (!await releaseDirectory.exists()) {
      _showError('Windows Release priečinok neexistuje.');
      return;
    }
    final executables = await releaseDirectory
        .list(followLinks: false)
        .where((entity) => entity is File && entity.path.toLowerCase().endsWith('.exe'))
        .cast<File>()
        .toList();
    if (executables.isEmpty) {
      _showError('Vo Windows Release priečinku sa nenašlo EXE.');
      return;
    }
    executables.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    await Process.start(
      executables.first.path,
      const <String>[],
      workingDirectory: releaseDirectory.path,
      runInShell: false,
    );
  }

  Future<void> _runOneClickBuild() async {
    if (_oneClickBuildRunning) return;
    final workspace = _gitWorkspacePath;
    if (workspace == null || workspace.trim().isEmpty) {
      _showError('Najprv vyber pracovný projekt.');
      return;
    }
    if (!await File(path.join(workspace, 'pubspec.yaml')).exists()) {
      _showError('Vybraný workspace nie je platný Flutter projekt. Chýba pubspec.yaml.');
      return;
    }
    final currentProject = await _pubspecService.readProject(workspace);
    if (mounted) {
      setState(() => _project = currentProject);
    }
    final buildIdentityAtStart = await _loadProjectIdentity(workspace);
    if (buildIdentityAtStart == null) {
      _showError('Z pubspec.yaml sa nepodarilo načítať aktuálnu verziu a build.');
      return;
    }
    if (currentProject.version != buildIdentityAtStart.version ||
        currentProject.releaseBuild != buildIdentityAtStart.build) {
      _showError(
        'Identita projektu nie je konzistentná. PubspecService: '
        '${currentProject.version}+${currentProject.releaseBuild}, provider: '
        '${buildIdentityAtStart.version}+${buildIdentityAtStart.build}.',
      );
      return;
    }
    _addLog(
      'One Click Build identita: ${buildIdentityAtStart.version}+'
      '${buildIdentityAtStart.build} ${buildIdentityAtStart.stage.toUpperCase()}.',
    );
    if (_oneClickBuildResumeIndex == 0) {
      final snapshot = await _createProjectSnapshot(
        label: 'Before build ${buildIdentityAtStart.build}',
      );
      if (snapshot == null) {
        _showError('Build bol zastavený, pretože sa nepodarilo vytvoriť bezpečnostný snapshot.');
        return;
      }
    }
    final buildStartedAt = DateTime.now();
    final steps = <({List<String> args, String label})>[
      (args: <String>['clean'], label: 'Flutter clean'),
      (args: <String>['pub', 'get'], label: 'Flutter pub get'),
      (args: <String>['analyze'], label: 'Flutter analyze'),
      (args: <String>['test'], label: 'Flutter test'),
      (args: <String>['build', 'windows', '--release'], label: 'Windows Release build'),
    ];
    final startIndex = _oneClickBuildResumeIndex.clamp(0, steps.length - 1);
    setState(() {
      _oneClickBuildRunning = true;
      _oneClickBuildCompletedSteps = startIndex;
      _oneClickBuildCurrentStep = startIndex == 0 ? 'Príprava' : 'Pokračovanie';
      _oneClickBuildFailedLabel = null;
      _oneClickBuildFailedArguments = const <String>[];
      _oneClickBuildFailedOutput = const <String>[];
      _oneClickBuildFailedExitCode = null;
      _oneClickBuildFailedError = null;
      _oneClickBuildFailedStackTrace = null;
    });
    _addLog(startIndex == 0
        ? '=== ZAČÍNA ONE CLICK BUILD ==='
        : '=== ONE CLICK BUILD POKRAČUJE OD KROKU ${steps[startIndex].label} ===');
    try {
      for (var index = startIndex; index < steps.length; index++) {
        final step = steps[index];
        final ok = await _runWorkspaceFlutterStep(workspace, step.args, step.label);
        if (!ok) {
          _oneClickBuildResumeIndex = index;
          await _showBuildFailureDialog(
            projectName: path.basename(workspace),
            projectPath: workspace,
            label: _oneClickBuildFailedLabel ?? step.label,
            arguments: _oneClickBuildFailedArguments.isEmpty
                ? step.args
                : _oneClickBuildFailedArguments,
            output: _oneClickBuildFailedOutput,
            exitCode: _oneClickBuildFailedExitCode,
            error: _oneClickBuildFailedError,
            stackTrace: _oneClickBuildFailedStackTrace,
          );
          return;
        }
      }
      _oneClickBuildResumeIndex = 0;
      await _refreshGitWorkspace();
      final identity = await _loadProjectIdentity(workspace);
      if (identity == null) {
        throw StateError(
          'Po zostavení sa nepodarilo znovu načítať verziu a build projektu.',
        );
      }
      if (identity.version != buildIdentityAtStart.version ||
          identity.build != buildIdentityAtStart.build) {
        throw StateError(
          'Identita projektu sa počas buildu zmenila z '
          '${buildIdentityAtStart.version}+${buildIdentityAtStart.build} na '
          '${identity.version}+${identity.build}. Build nebude označený ani exportovaný.',
        );
      }
      _addLog(
        '=== ONE CLICK BUILD ${identity.version}+${identity.build} '
        'BOL ÚSPEŠNE DOKONČENÝ ===',
      );
      final buildReportFile = await _writeSuccessfulBuildReport(
        projectPath: workspace,
        startedAt: buildStartedAt,
      );
      File? releaseZipFile;
      Object? releaseZipError;
      try {
        releaseZipFile = await _createOneClickReleaseZip(workspace);
      } catch (error, stackTrace) {
        releaseZipError = error;
        _addLog('Export Release ZIP sa nepodarilo vytvoriť: $error');
        await _writeCrashLog(
          error,
          stackTrace,
          step: 'One Click Build – Export Release ZIP',
          projectPath: workspace,
        );
      }
      final buildDuration = DateTime.now().difference(buildStartedAt);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(children: <Widget>[
            const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('BUILD ${identity.build} úspešne dokončený'),
            ),
          ]),
          content: SizedBox(
            width: 640,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Projekt: ${path.basename(workspace)}'),
                Text(
                  'Verzia: ${identity.version} '
                  '${identity.stage.toUpperCase()}',
                ),
                Text(
                  'Čas buildu: ${buildDuration.inMinutes} min '
                  '${buildDuration.inSeconds.remainder(60)} s',
                ),
                const SizedBox(height: 14),
                const Text(
                  '✔ Flutter clean\n'
                  '✔ Flutter pub get\n'
                  '✔ Flutter analyze\n'
                  '✔ Flutter test\n'
                  '✔ Windows Release build',
                ),
                const SizedBox(height: 14),
                Text('Build report: ${buildReportFile.path}'),
                if (releaseZipFile != null)
                  Text('Export Release ZIP: ${releaseZipFile.path}'),
                if (releaseZipError != null)
                  Text(
                    '⚠ Export Release ZIP sa nepodarilo vytvoriť: '
                    '$releaseZipError',
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Aplikáciu teraz otestuj. Po úspešnom teste môžeš '
                  'build uložiť priamo do Gitu.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton.icon(
              onPressed: () => _selectFileInExplorer(buildReportFile.path),
              icon: const Icon(Icons.description_outlined),
              label: const Text('REPORT'),
            ),
            if (releaseZipFile != null)
              TextButton.icon(
                onPressed: () => _selectFileInExplorer(releaseZipFile!.path),
                icon: const Icon(Icons.archive_outlined),
                label: const Text('EXPORT RELEASE ZIP'),
              ),
            TextButton.icon(
              onPressed: () => _launchOneClickWindowsBuild(workspace),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('TEST EXE'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ZAVRIEŤ'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showGitBuildPublisherDialog();
              },
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('ULOŽIŤ BUILD DO GITU'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _oneClickBuildRunning = false;
          _oneClickBuildCurrentStep = 'Čaká';
        });
      }
    }
  }


  Future<void> _analyzeCurrentProject() async {
    final workspace = _gitWorkspacePath;
    if (workspace == null || workspace.trim().isEmpty) {
      _showError('Najprv vyber pracovný projekt.');
      return;
    }
    setState(() {
      _projectAnalysisRunning = true;
      _projectAnalysisError = null;
    });
    try {
      final result = await _projectAnalyzerService.analyze(workspace);
      if (!mounted) return;
      setState(() {
        _projectAnalysis = result;
        _projectAnalysisRunning = false;
      });
      _addLog('Project Analyzer dokončený: ${result.modules.length} modulov, ${result.screens.length} obrazoviek, ${result.databaseTables.length} tabuliek.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _projectAnalysisRunning = false;
        _projectAnalysisError = error.toString();
      });
    }
  }

  Future<void> _openAnalyzerSourceFile(String relativeFile, {int? line}) async {
    final workspace = _gitWorkspacePath;
    if (workspace == null || workspace.trim().isEmpty) return;
    final fullPath = path.join(workspace, 'lib', relativeFile.replaceAll('/', path.separator));
    if (!await File(fullPath).exists()) {
      _showError('Súbor neexistuje: $fullPath');
      return;
    }
    try {
      if (Platform.isWindows) {
        await Process.start('cmd', <String>['/c', 'start', '', fullPath], runInShell: true);
      } else {
        await Process.start('xdg-open', <String>[fullPath]);
      }
      _addLog('Otváram zdrojový súbor: $fullPath${line == null ? '' : ':$line'}');
    } catch (error) {
      _showError('Súbor sa nepodarilo otvoriť: $error');
    }
  }

  bool _analyzerMatches(String value) {
    final query = _projectAnalyzerSearchQuery.trim().toLowerCase();
    return query.isEmpty || value.toLowerCase().contains(query);
  }

  bool _analyzerModuleMatchesFilter(ProjectModuleAnalysis module) {
    switch (_projectAnalyzerFilter) {
      case 'screens':
        return module.screens.isNotEmpty;
      case 'services':
        return module.services.isNotEmpty;
      case 'database':
        return module.databaseTables.isNotEmpty;
      case 'todo':
        return module.todos.isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _exportProjectAnalyzerMap() async {
    final analysis = _projectAnalysis;
    final workspace = _gitWorkspacePath;
    if (analysis == null || workspace == null || workspace.trim().isEmpty) {
      _showError('Najprv analyzuj pracovný projekt.');
      return;
    }
    try {
      final outputDirectory = Directory(path.join(workspace, 'diagnostics'));
      await outputDirectory.create(recursive: true);
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final outputFile = File(path.join(outputDirectory.path, 'PROJECT_MAP_$stamp.txt'));
      final buffer = StringBuffer()
        ..writeln('STAVBY PRO RELEASE MANAGER – PROJECT MAP')
        ..writeln('=' * 56)
        ..writeln('Projekt: ${analysis.projectPath}')
        ..writeln('Vygenerované: ${analysis.generatedAt.toIso8601String()}')
        ..writeln('Dart súbory: ${analysis.dartFiles}')
        ..writeln('Moduly: ${analysis.modules.length}')
        ..writeln('Obrazovky: ${analysis.screens.length}')
        ..writeln('DB tabuľky: ${analysis.databaseTables.length}')
        ..writeln('Routes: ${analysis.routes.length}')
        ..writeln('TODO/FIXME/HACK: ${analysis.todos.length}')
        ..writeln();
      for (final module in analysis.modules) {
        buffer
          ..writeln('MODUL: ${module.name}')
          ..writeln('-' * 56)
          ..writeln('Dart súbory: ${module.dartFiles}')
          ..writeln('Obrazovky: ${module.screens.join(', ')}')
          ..writeln('Služby: ${module.services.join(', ')}')
          ..writeln('DB tabuľky: ${module.databaseTables.join(', ')}')
          ..writeln('Routes: ${module.routes.join(', ')}')
          ..writeln('Zdrojové súbory:')
          ..writeln(module.relativeFiles.map((value) => '  - $value').join('\n'))
          ..writeln();
      }
      await outputFile.writeAsString(buffer.toString(), encoding: utf8, flush: true);
      _addLog('Project Map bol exportovaný: ${outputFile.path}');
      await _selectFileInExplorer(outputFile.path);
    } catch (error) {
      _showError('Project Map sa nepodarilo exportovať: $error');
    }
  }

  void _setAnalyzerExpansion(bool expanded) {
    setState(() {
      _projectAnalyzerExpandAll = expanded;
      _projectAnalyzerExpansionGeneration++;
    });
  }

  Widget _buildAnalyzerModulesCard(List<ProjectModuleAnalysis> modules) {
    final filteredModules = modules.where((module) {
      if (!_analyzerModuleMatchesFilter(module)) return false;
      if (_projectAnalyzerSearchQuery.trim().isEmpty) return true;
      final values = <String>[
        module.name,
        ...module.screens,
        ...module.services,
        ...module.databaseTables,
        ...module.routes,
        ...module.relativeFiles,
        ...module.todos.map((todo) => '${todo.kind} ${todo.message} ${todo.relativeFile}'),
      ];
      return values.any(_analyzerMatches);
    }).toList();

    return RMSectionCard(
      title: 'Interaktívna mapa modulov',
      child: filteredModules.isEmpty
          ? const Text('Vyhľadávaniu nezodpovedá žiadny modul.')
          : Column(
              children: filteredModules.map((module) {
                Widget chips(String label, IconData icon, List<String> values, {bool files = false}) {
                  final filtered = values.where(_analyzerMatches).toList();
                  if (filtered.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: filtered.take(100).map((value) => ActionChip(
                          avatar: Icon(icon, size: 15),
                          label: Text(value),
                          onPressed: files ? () => _openAnalyzerSourceFile(value) : null,
                        )).toList(),
                      ),
                    ]),
                  );
                }

                final healthy = module.healthWarnings == 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    key: ValueKey<String>('analyzer_${module.name}_$_projectAnalyzerExpansionGeneration'),
                    initiallyExpanded: _projectAnalyzerExpandAll,
                    leading: Icon(
                      healthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                      color: healthy ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
                    ),
                    title: Row(children: <Widget>[
                      Expanded(child: Text(module.name, style: const TextStyle(fontWeight: FontWeight.w900))),
                      Chip(
                        avatar: Icon(healthy ? Icons.health_and_safety_rounded : Icons.task_alt_rounded, size: 15),
                        label: Text(module.healthLabel),
                        visualDensity: VisualDensity.compact,
                      ),
                    ]),
                    subtitle: Text(
                      '${module.dartFiles} Dart súborov • ${module.screens.length} obrazoviek • '
                      '${module.services.length} služieb • ${module.databaseTables.length} DB tabuliek',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: module.relativeFiles.isEmpty
                              ? null
                              : () => _openAnalyzerSourceFile(module.relativeFiles.first),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('OTVORIŤ MODUL'),
                        ),
                      ),
                      chips('Obrazovky a dialógy', Icons.web_asset_rounded, module.screens),
                      chips('Služby, controllery a repository', Icons.settings_suggest_rounded, module.services),
                      chips('Databázové tabuľky', Icons.storage_rounded, module.databaseTables),
                      chips('Navigačné cesty', Icons.route_rounded, module.routes),
                      chips('Zdrojové súbory – kliknutím otvoríš', Icons.description_outlined, module.relativeFiles, files: true),
                      if (module.todos.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('TODO / FIXME / HACK', style: Theme.of(context).textTheme.titleSmall),
                        ),
                        const SizedBox(height: 6),
                        ...module.todos.where((todo) => _analyzerMatches('${todo.kind} ${todo.message} ${todo.relativeFile}')).map(
                          (todo) => ListTile(
                            dense: true,
                            leading: Icon(
                              todo.kind == 'FIXME' ? Icons.error_outline_rounded : Icons.task_alt_rounded,
                              color: todo.kind == 'FIXME' ? const Color(0xFFC62828) : const Color(0xFFF57C00),
                            ),
                            title: Text('${todo.kind}: ${todo.message.isEmpty ? '(bez popisu)' : todo.message}'),
                            subtitle: Text('${todo.relativeFile}:${todo.line}'),
                            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                            onTap: () => _openAnalyzerSourceFile(todo.relativeFile, line: todo.line),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildProjectAnalyzerPage() {
    final analysis = _projectAnalysis;

    Widget metric(IconData icon, String label, String value) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: <Widget>[
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
          Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        ])),
      ]),
    );

    Widget listCard(String title, IconData icon, List<String> values) {
      final filtered = values.where(_analyzerMatches).toList();
      return RMSectionCard(
        title: title,
        child: filtered.isEmpty
            ? const Text('Neboli nájdené žiadne zodpovedajúce položky.')
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filtered.take(120).map((value) => Chip(
                  avatar: Icon(icon, size: 16),
                  label: Text(value),
                )).toList(),
              ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      RMSectionCard(
        title: '🧠 Project Analyzer V3 – Search & Health',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
          Text(_gitWorkspacePath ?? 'Nie je vybraný pracovný projekt.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _projectAnalysisRunning ? null : _analyzeCurrentProject,
                icon: _projectAnalysisRunning
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded),
                label: Text(_projectAnalysisRunning ? 'ANALYZUJEM PROJEKT…' : analysis == null ? 'ANALYZOVAŤ PROJEKT' : 'OBNOVIŤ ANALÝZU'),
              ),
              OutlinedButton.icon(
                onPressed: analysis == null ? null : _exportProjectAnalyzerMap,
                icon: const Icon(Icons.description_outlined),
                label: const Text('EXPORT PROJECT MAP'),
              ),
              OutlinedButton.icon(
                onPressed: analysis == null ? null : () => _setAnalyzerExpansion(true),
                icon: const Icon(Icons.unfold_more_rounded),
                label: const Text('ROZBALIŤ VŠETKO'),
              ),
              OutlinedButton.icon(
                onPressed: analysis == null ? null : () => _setAnalyzerExpansion(false),
                icon: const Icon(Icons.unfold_less_rounded),
                label: const Text('ZBALIŤ VŠETKO'),
              ),
            ],
          ),
          if (analysis != null) ...<Widget>[
            const SizedBox(height: 12),
            TextField(
              controller: _projectAnalyzerSearchController,
              onChanged: (value) => setState(() => _projectAnalyzerSearchQuery = value),
              decoration: InputDecoration(
                labelText: 'Hľadať modul, súbor, obrazovku, službu, tabuľku alebo TODO',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _projectAnalyzerSearchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Vymazať vyhľadávanie',
                        onPressed: () {
                          _projectAnalyzerSearchController.clear();
                          setState(() => _projectAnalyzerSearchQuery = '');
                        },
                        icon: const Icon(Icons.clear_rounded),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final item in const <(String, String, IconData)>[
                  ('all', 'Všetko', Icons.apps_rounded),
                  ('screens', 'Obrazovky', Icons.web_asset_rounded),
                  ('services', 'Služby', Icons.settings_suggest_rounded),
                  ('database', 'Databáza', Icons.storage_rounded),
                  ('todo', 'TODO / FIXME', Icons.task_alt_rounded),
                ])
                  ChoiceChip(
                    selected: _projectAnalyzerFilter == item.$1,
                    avatar: Icon(item.$3, size: 16),
                    label: Text(item.$2),
                    onSelected: (_) => setState(() => _projectAnalyzerFilter = item.$1),
                  ),
              ],
            ),
          ],
          if (_projectAnalysisError != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(_projectAnalysisError!, style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w700)),
          ],
        ]),
      ),
      if (analysis != null) ...<Widget>[
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final metrics = <Widget>[
            metric(Icons.code_rounded, 'DART SÚBORY', analysis.dartFiles.toString()),
            metric(Icons.extension_rounded, 'MODULY', analysis.modules.length.toString()),
            metric(Icons.web_asset_rounded, 'OBRAZOVKY', analysis.screens.length.toString()),
            metric(Icons.storage_rounded, 'DB TABUĽKY', analysis.databaseTables.length.toString()),
            metric(Icons.task_alt_rounded, 'TODO / FIXME', analysis.todos.length.toString()),
          ];
          if (constraints.maxWidth < 900) {
            return Column(children: metrics.expand((e) => <Widget>[e, const SizedBox(height: 8)]).toList()..removeLast());
          }
          return Row(children: metrics.expand((e) => <Widget>[Expanded(child: e), const SizedBox(width: 8)]).toList()..removeLast());
        }),
        const SizedBox(height: 16),
        _buildAnalyzerModulesCard(analysis.modules),
        const SizedBox(height: 16),
        if (analysis.todos.isNotEmpty)
          RMSectionCard(
            title: 'TODO / FIXME / HACK Scanner',
            child: Column(
              children: analysis.todos
                  .where((todo) => _analyzerMatches('${todo.kind} ${todo.message} ${todo.relativeFile}'))
                  .take(200)
                  .map((todo) => ListTile(
                        dense: true,
                        leading: Icon(
                          todo.kind == 'FIXME' ? Icons.error_outline_rounded : Icons.task_alt_rounded,
                          color: todo.kind == 'FIXME' ? const Color(0xFFC62828) : const Color(0xFFF57C00),
                        ),
                        title: Text('${todo.kind}: ${todo.message.isEmpty ? '(bez popisu)' : todo.message}'),
                        subtitle: Text('${todo.relativeFile}:${todo.line}${todo.module == null ? '' : ' • ${todo.module}'}'),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                        onTap: () => _openAnalyzerSourceFile(todo.relativeFile, line: todo.line),
                      ))
                  .toList(),
            ),
          ),
        if (analysis.todos.isNotEmpty) const SizedBox(height: 16),
        listCard('Obrazovky a dialógy', Icons.web_asset_rounded, analysis.screens),
        const SizedBox(height: 16),
        listCard('Služby, controllery a repository', Icons.settings_suggest_rounded, analysis.services),
        const SizedBox(height: 16),
        listCard('Databázové tabuľky', Icons.storage_rounded, analysis.databaseTables),
        const SizedBox(height: 16),
        listCard('Navigačné cesty', Icons.route_rounded, analysis.routes),
      ],
    ]);
  }

  Widget _buildProjectDashboardCard() {
    final workspace = _gitWorkspacePath;
    final status = _gitWorkspaceStatus;
    final isRepository = status?.isRepository == true;
    final lastCommit = _gitHistory.isEmpty ? null : _gitHistory.first;
    final lastTag = _gitHistory
        .expand((entry) => entry.tags)
        .cast<String?>()
        .firstWhere((tag) => tag != null && tag.trim().isNotEmpty, orElse: () => null);
    final clean = status?.isClean == true;

    Widget infoTile(IconData icon, String label, String value, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (workspace == null || workspace.trim().isEmpty) {
      return RMSectionCard(
        title: '🧭 Project Dashboard',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('Nie je vybraný žiadny Git pracovný projekt.'),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _gitWorkspaceLoading ? null : _chooseGitWorkspace,
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('VYBRAŤ PRACOVNÝ PROJEKT'),
            ),
          ],
        ),
      );
    }

    final identity = _projectIdentitySnapshot;
    return Builder(
      builder: (context) {
        final projectName = path.basename(workspace);
        final versionText = identity == null
            ? (_projectIdentityLoading ? 'Načítavam…' : 'Nezistená')
            : '${identity.version} ${identity.stage.toUpperCase()}';
        final buildText = identity == null
            ? (_projectIdentityLoading ? '…' : '—')
            : identity.build.toString();
        return RMSectionCard(
          title: '🧭 Project Dashboard',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.apps_rounded, color: Color(0xFF2E7D32), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(projectName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        Tooltip(
                          message: workspace,
                          child: Text(workspace, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (clean ? const Color(0xFF2E7D32) : const Color(0xFFF57C00)).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      clean ? 'GIT ČISTÝ' : '${status?.changedFiles.length ?? 0} ZMIEN',
                      style: TextStyle(
                        color: clean ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final tiles = <Widget>[
                    infoTile(Icons.sell_rounded, 'VERZIA', versionText, const Color(0xFF1565C0)),
                    infoTile(Icons.numbers_rounded, 'BUILD', buildText, const Color(0xFF6A1B9A)),
                    infoTile(Icons.account_tree_rounded, 'VETVA', status?.branch ?? '—', const Color(0xFF2E7D32)),
                    infoTile(Icons.commit_rounded, 'POSLEDNÝ COMMIT', lastCommit == null ? '—' : '${lastCommit.shortSha} • ${lastCommit.subject}', const Color(0xFFE65100)),
                    infoTile(Icons.local_offer_rounded, 'POSLEDNÝ TAG', lastTag ?? '—', const Color(0xFF00897B)),
                  ];
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: tiles
                          .expand((tile) => <Widget>[tile, const SizedBox(height: 8)])
                          .toList()
                        ..removeLast(),
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (var i = 0; i < tiles.length; i++) ...<Widget>[
                        Expanded(child: tiles[i]),
                        if (i != tiles.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  );
                },
              ),
              if (!isRepository) ...<Widget>[
                const SizedBox(height: 10),
                const Text('Vybraný priečinok nie je platný Git repozitár.', style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: isRepository && !_oneClickBuildRunning ? _runOneClickBuild : null,
                    icon: _oneClickBuildRunning
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.rocket_launch_rounded),
                    label: Text(_oneClickBuildRunning
                        ? 'BUILD: $_oneClickBuildCurrentStep'
                        : (_oneClickBuildResumeIndex > 0
                            ? 'POKRAČOVAŤ OD ${_oneClickBuildFailedLabel ?? 'CHYBY'}'
                            : 'SPUSTIŤ CELÝ BUILD')),
                  ),
                  if (_oneClickBuildResumeIndex > 0)
                    OutlinedButton.icon(
                      onPressed: _oneClickBuildRunning
                          ? null
                          : () => setState(() {
                                _oneClickBuildResumeIndex = 0;
                                _oneClickBuildFailedLabel = null;
                              }),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('ZAČAŤ OD ZAČIATKU'),
                    ),
                  OutlinedButton.icon(
                    onPressed: isRepository ? () => setState(() => _selectedPage = 6) : null,
                    icon: const Icon(Icons.developer_mode_rounded),
                    label: const Text('DEVELOPER CENTER'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _gitWorkspaceLoading ? null : _chooseGitWorkspace,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('ZMENIŤ PROJEKT'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _workspaceSyncRunning ? null : _synchronizeDevelopmentZip,
                    icon: _workspaceSyncRunning
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.folder_zip_rounded),
                    label: Text(_workspaceSyncRunning ? 'SYNCHRONIZUJEM...' : 'SYNCHRONIZOVAŤ ZIP'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _gitWorkspaceLoading ? null : _refreshGitWorkspace,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('OBNOVIŤ STAV'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _showBuildCompletionCenter() async {
    final workspace = _gitWorkspacePath?.trim();
    final status = _gitWorkspaceStatus;
    final identity = workspace == null || workspace.isEmpty
        ? null
        : await _readGitBuildIdentity(workspace);
    if (!mounted) return;

    final preferencesFile = workspace == null || workspace.isEmpty
        ? null
        : File(path.join(workspace, '.release_manager', 'build_completion_preferences.json'));
    Map<String, dynamic> savedPreferences = <String, dynamic>{};
    if (preferencesFile != null && await preferencesFile.exists()) {
      try {
        final decoded = jsonDecode(await preferencesFile.readAsString());
        if (decoded is Map<String, dynamic>) savedPreferences = decoded;
      } catch (error) {
        _addLog('Build Completion Center: nastavenia sa nepodarilo načítať: $error');
      }
    }

    String inferReleaseType() {
      final stage = identity?.stage.toUpperCase() ?? '';
      if (stage.contains('FINAL')) return 'FINAL';
      if (stage.contains('RC')) return 'RC';
      if (stage.contains('FIX')) return 'FIX';
      return 'DEV';
    }

    var releaseType = (savedPreferences['releaseType'] as String?) ?? inferReleaseType();
    final commitController = TextEditingController();
    final changesController = TextEditingController();
    final notesController = TextEditingController();
    final tagController = TextEditingController(
      text: identity == null ? '' : _gitTagForBuild(identity),
    );

    var createCommit = (savedPreferences['commit'] as bool?) ?? true;
    var pushToRemote = (savedPreferences['push'] as bool?) ?? true;
    var createTag = (savedPreferences['tag'] as bool?) ?? false;
    var exportZip = (savedPreferences['exportZip'] as bool?) ?? true;
    var createReport = (savedPreferences['buildReport'] as bool?) ?? true;
    var writeHistory = (savedPreferences['history'] as bool?) ?? true;
    var synchronizeZip = (savedPreferences['synchronizeZip'] as bool?) ?? false;
    String? validationMessage;

    String suggestedCommitMessage() {
      if (identity == null || workspace == null || workspace.isEmpty) return '';
      final project = path.basename(workspace);
      final stage = identity.stage.trim();
      switch (releaseType) {
        case 'FIX':
          return '$project ${identity.version} Build ${identity.build} - $stage';
        case 'RC':
          return '$project ${identity.version} RC - Build ${identity.build}';
        case 'FINAL':
          return '$project ${identity.version} FINAL - Build ${identity.build}';
        default:
          return '$project ${identity.version} DEV Build ${identity.build} - $stage';
      }
    }

    String suggestedDescription() {
      final project = workspace == null || workspace.isEmpty ? 'Projekt' : path.basename(workspace);
      final changed = status?.changedFiles.length ?? 0;
      final typeLine = switch (releaseType) {
        'FIX' => '- Opravené chyby a stabilizované správanie aktuálneho buildu',
        'RC' => '- Pripravený kandidát na vydanie a dokončená predvýdajová kontrola',
        'FINAL' => '- Pripravené finálne stabilné vydanie projektu',
        _ => '- Zapracované plánované zmeny vývojového buildu',
      };
      return <String>[
        typeLine,
        '- Projekt: $project',
        if (identity != null) '- Verzia: ${identity.version} • Build ${identity.build}',
        if (changed > 0) '- Zmenené súbory pred dokončením: $changed',
        '- Build úspešne otestovaný',
      ].join('\n');
    }

    String suggestedTag() {
      if (identity == null) return '';
      final version = identity.version;
      switch (releaseType) {
        case 'RC':
          return 'v$version-rc1';
        case 'FINAL':
          return 'v$version';
        case 'FIX':
          return 'v$version-build${identity.build}-fix';
        default:
          return 'v$version-build${identity.build}';
      }
    }

    void applyRecommendedOptions() {
      createCommit = true;
      pushToRemote = true;
      exportZip = true;
      createReport = true;
      writeHistory = true;
      createTag = releaseType == 'RC' || releaseType == 'FINAL';
      synchronizeZip = releaseType == 'FINAL';
      tagController.text = suggestedTag();
    }

    commitController.text = suggestedCommitMessage();

    if (!mounted) return;
    final completionData = await showDialog<Map<String, Object?>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final workspaceReady = workspace != null && workspace.isNotEmpty;
          final gitReady = status?.isRepository == true;
          final identityReady = identity != null;

          Widget checkRow({
            required IconData icon,
            required String label,
            required bool ok,
          }) {
            final color = ok ? const Color(0xFF2E7D32) : const Color(0xFFF57C00);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(ok ? Icons.check_circle_rounded : icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
            );
          }

          Widget option({
            required String title,
            required String subtitle,
            required bool value,
            required ValueChanged<bool?> onChanged,
          }) {
            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(subtitle),
              value: value,
              onChanged: onChanged,
            );
          }

          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(22, 18, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            title: Row(
              children: <Widget>[
                const Icon(Icons.task_alt_rounded, color: Color(0xFF2E7D32)),
                const SizedBox(width: 10),
                const Expanded(child: Text('Build Completion Center')),
                IconButton(
                  tooltip: 'Zavrieť',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            content: SizedBox(
              width: 860,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Wrap(
                        spacing: 18,
                        runSpacing: 8,
                        children: <Widget>[
                          Text('Projekt: ${workspaceReady ? path.basename(workspace) : '—'}', style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text('Verzia: ${identity?.version ?? '—'}'),
                          Text('Build: ${identity?.build ?? '—'}'),
                          Text('Vetva: ${status?.branch ?? '—'}'),
                          Text('Zmeny: ${status?.changedFiles.length ?? 0}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Typ vydania', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final type in const <String>['DEV', 'FIX', 'RC', 'FINAL'])
                          ChoiceChip(
                            label: Text(type),
                            selected: releaseType == type,
                            onSelected: (_) => setDialogState(() {
                              releaseType = type;
                              applyRecommendedOptions();
                              commitController.text = suggestedCommitMessage();
                              changesController.text = suggestedDescription();
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45)),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: () => setDialogState(() => commitController.text = suggestedCommitMessage()),
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: const Text('NAVRHNÚŤ COMMIT'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => setDialogState(() => changesController.text = suggestedDescription()),
                            icon: const Icon(Icons.notes_rounded),
                            label: const Text('NAVRHNÚŤ POPIS'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => setDialogState(() {
                              applyRecommendedOptions();
                              commitController.text = suggestedCommitMessage();
                              changesController.text = suggestedDescription();
                            }),
                            icon: const Icon(Icons.auto_fix_high_rounded),
                            label: const Text('VYPLNIŤ VŠETKO'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commitController,
                      decoration: const InputDecoration(
                        labelText: 'Commit Message',
                        hintText: 'Build 284 DEV - Equipment Type Consistency',
                        prefixIcon: Icon(Icons.commit_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: changesController,
                      minLines: 4,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Popis zmien',
                        hintText: '- Zmena 1\n- Oprava 2\n- Build úspešne otestovaný',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 78),
                          child: Icon(Icons.description_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Interné poznámky (voliteľné)',
                        hintText: 'Nezobrazia sa v GitHub Release ani v changelogu.',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.sticky_note_2_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 760;
                        final left = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            option(title: 'Vytvoriť commit', subtitle: 'git add + commit', value: createCommit, onChanged: (v) => setDialogState(() => createCommit = v ?? false)),
                            option(title: 'Push na GitHub', subtitle: 'Odošle aktuálnu vetvu', value: pushToRemote, onChanged: (v) => setDialogState(() => pushToRemote = v ?? false)),
                            option(title: 'Vytvoriť tag', subtitle: 'Použi iba pri míľniku', value: createTag, onChanged: (v) => setDialogState(() => createTag = v ?? false)),
                            if (createTag)
                              TextField(controller: tagController, decoration: const InputDecoration(labelText: 'Git tag', prefixIcon: Icon(Icons.sell_rounded))),
                          ],
                        );
                        final right = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            option(title: 'Exportovať Release ZIP', subtitle: 'Pripraví distribučný archív', value: exportZip, onChanged: (v) => setDialogState(() => exportZip = v ?? false)),
                            option(title: 'Vytvoriť Build Report', subtitle: 'Uloží výsledok buildu', value: createReport, onChanged: (v) => setDialogState(() => createReport = v ?? false)),
                            option(title: 'Zapísať do histórie', subtitle: 'Evidencia dokončených buildov', value: writeHistory, onChanged: (v) => setDialogState(() => writeHistory = v ?? false)),
                            option(title: 'Synchronizovať záložný ZIP', subtitle: 'Voliteľná bezpečnostná kópia', value: synchronizeZip, onChanged: (v) => setDialogState(() => synchronizeZip = v ?? false)),
                          ],
                        );
                        return columns
                            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Expanded(child: left), const SizedBox(width: 18), Expanded(child: right)])
                            : Column(children: <Widget>[left, const Divider(height: 24), right]);
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        SizedBox(width: 250, child: checkRow(icon: Icons.folder_off_rounded, label: workspaceReady ? 'Workspace je vybraný' : 'Workspace nie je vybraný', ok: workspaceReady)),
                        SizedBox(width: 250, child: checkRow(icon: Icons.account_tree_rounded, label: gitReady ? 'Git repozitár je pripravený' : 'Git repozitár nie je pripravený', ok: gitReady)),
                        SizedBox(width: 250, child: checkRow(icon: Icons.numbers_rounded, label: identityReady ? 'Verzia a build načítané' : 'Verziu a build sa nepodarilo načítať', ok: identityReady)),
                      ],
                    ),
                    if (validationMessage != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(validationMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w800)),
                    ],
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('ZRUŠIŤ')),
              FilledButton.icon(
                onPressed: () async {
                  final commit = commitController.text.trim();
                  final changes = changesController.text.trim();
                  if (!workspaceReady || !identityReady || commit.isEmpty || changes.isEmpty || (createTag && tagController.text.trim().isEmpty)) {
                    setDialogState(() {
                      validationMessage = 'Vyber workspace a vyplň Commit Message, Popis zmien a prípadný tag.';
                    });
                    return;
                  }
                  final data = <String, Object?>{
                    'project': path.basename(workspace),
                    'workspace': workspace,
                    'version': identity.version,
                    'build': identity.build,
                    'stage': identity.stage,
                    'releaseType': releaseType,
                    'branch': status?.branch,
                    'commitMessage': commit,
                    'changeDescription': changes,
                    'internalNotes': notesController.text.trim(),
                    'options': <String, bool>{
                      'commit': createCommit,
                      'push': pushToRemote,
                      'tag': createTag,
                      'exportZip': exportZip,
                      'buildReport': createReport,
                      'history': writeHistory,
                      'synchronizeZip': synchronizeZip,
                    },
                    'tagName': createTag ? tagController.text.trim() : '',
                    'savedAt': DateTime.now().toIso8601String(),
                  };
                  final directory = Directory(path.join(workspace, '.release_manager'));
                  await directory.create(recursive: true);
                  final preferences = <String, Object?>{
                    'releaseType': releaseType,
                    'commit': createCommit,
                    'push': pushToRemote,
                    'tag': createTag,
                    'exportZip': exportZip,
                    'buildReport': createReport,
                    'history': writeHistory,
                    'synchronizeZip': synchronizeZip,
                  };
                  await File(path.join(directory.path, 'build_completion_preferences.json'))
                      .writeAsString(const JsonEncoder.withIndent('  ').convert(preferences));
                  final draft = File(path.join(directory.path, 'build_completion_draft.json'));
                  await draft.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop(data);
                },
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('DOKONČIŤ A ULOŽIŤ BUILD'),
              ),
            ],
          );
        },
      ),
    );

    commitController.dispose();
    changesController.dispose();
    notesController.dispose();
    tagController.dispose();

    if (completionData != null && mounted) {
      await _executeBuildCompletion(completionData);
    }
  }

  Future<ProcessResult> _runGitCommand(
    String workspace,
    List<String> arguments, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final process = await Process.start(
      'git',
      arguments,
      workingDirectory: workspace,
      runInShell: true,
    );
    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    try {
      final exitCode = await process.exitCode.timeout(timeout);
      final stdoutText = await stdoutFuture;
      final stderrText = await stderrFuture;
      return ProcessResult(process.pid, exitCode, stdoutText, stderrText);
    } on TimeoutException {
      process.kill(ProcessSignal.sigterm);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      process.kill(ProcessSignal.sigkill);
      throw TimeoutException(
        'Git príkaz prekročil limit ${timeout.inSeconds} s: git ${arguments.join(' ')}',
        timeout,
      );
    }
  }

  Future<void> _removeStaleGitIndexLock(String workspace) async {
    final lock = File(path.join(workspace, '.git', 'index.lock'));
    if (!await lock.exists()) return;
    final modified = await lock.lastModified();
    final age = DateTime.now().difference(modified);
    if (age < const Duration(minutes: 2)) {
      throw StateError(
        'Git index je uzamknutý aktívnym procesom (.git/index.lock). Počkaj alebo ukonči iný Git proces.',
      );
    }
    await lock.delete();
    _addLog('Git preflight: odstránený zastaraný .git/index.lock (${age.inMinutes} min).');
  }

  Future<List<Map<String, Object?>>> _findTrackedLargeFiles(
    String workspace, {
    int limitBytes = 100 * 1024 * 1024,
  }) async {
    final result = await _runGitCommand(
      workspace,
      <String>['ls-files', '-z'],
      timeout: const Duration(seconds: 30),
    );
    if (result.exitCode != 0) {
      throw StateError('Kontrola veľkých súborov zlyhala: ${result.stderr.toString().trim()}');
    }

    final files = result.stdout.toString().split('\u0000');
    final largeFiles = <Map<String, Object?>>[];
    for (final relativePath in files) {
      if (relativePath.trim().isEmpty) continue;
      final file = File(path.join(workspace, relativePath));
      if (!await file.exists()) continue;
      final bytes = await file.length();
      if (bytes >= limitBytes) {
        largeFiles.add(<String, Object?>{
          'path': relativePath.replaceAll('\\', '/'),
          'bytes': bytes,
          'megabytes': bytes / (1024 * 1024),
          'source': 'index',
        });
      }
    }
    return largeFiles;
  }

  Future<bool> _gitRemoteExists(
    String workspace, {
    String remoteName = 'origin',
  }) async {
    final result = await _runGitCommand(
      workspace,
      <String>['remote', 'get-url', remoteName],
      timeout: const Duration(seconds: 15),
    );
    return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
  }

  Future<String> _originBranchRef(String workspace, String branch) async {
    final fetch = await _runGitCommand(
      workspace,
      <String>['fetch', '--no-tags', 'origin', branch],
      timeout: const Duration(seconds: 45),
    );
    if (fetch.exitCode != 0) {
      throw StateError('Git fetch zlyhal: ${fetch.stderr.toString().trim()}');
    }
    final ref = 'origin/$branch';
    final verify = await _runGitCommand(
      workspace,
      <String>['rev-parse', '--verify', ref],
      timeout: const Duration(seconds: 15),
    );
    if (verify.exitCode != 0) {
      throw StateError('Vzdialená vetva $ref neexistuje. Najprv ju vytvor alebo nastav správny origin.');
    }
    return ref;
  }

  Future<List<Map<String, Object?>>> _findOutgoingLargeBlobs(
    String workspace,
    String branch, {
    int limitBytes = 100 * 1024 * 1024,
  }) async {
    final baseRef = await _originBranchRef(workspace, branch);
    final revList = await _runGitCommand(
      workspace,
      <String>['rev-list', '--objects', '$baseRef..HEAD'],
      timeout: const Duration(seconds: 30),
    );
    if (revList.exitCode != 0) {
      throw StateError('Kontrola odosielanej Git histórie zlyhala: ${revList.stderr.toString().trim()}');
    }

    final objectLines = revList.stdout
        .toString()
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (objectLines.isEmpty) return <Map<String, Object?>>[];

    final process = await Process.start(
      'git',
      <String>['cat-file', '--batch-check=%(objecttype) %(objectname) %(objectsize) %(rest)'],
      workingDirectory: workspace,
      runInShell: true,
    );
    final outputFuture = process.stdout.transform(utf8.decoder).join();
    final errorFuture = process.stderr.transform(utf8.decoder).join();
    process.stdin.write('${objectLines.join('\n')}\n');
    await process.stdin.close();
    late final int exitCode;
    try {
      exitCode = await process.exitCode.timeout(const Duration(seconds: 45));
    } on TimeoutException {
      process.kill(ProcessSignal.sigterm);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      process.kill(ProcessSignal.sigkill);
      throw TimeoutException('Čítanie Git objektov prekročilo limit 45 sekúnd.');
    }
    final output = await outputFuture;
    final error = await errorFuture;
    if (exitCode != 0) {
      throw StateError('Čítanie Git objektov zlyhalo: ${error.trim()}');
    }

    final results = <Map<String, Object?>>[];
    for (final line in output.split(RegExp(r'\r?\n'))) {
      final match = RegExp(r'^(\S+)\s+(\S+)\s+(\d+)(?:\s+(.*))?$').firstMatch(line.trim());
      if (match == null || match.group(1) != 'blob') continue;
      final bytes = int.tryParse(match.group(3) ?? '') ?? 0;
      if (bytes < limitBytes) continue;
      final relativePath = (match.group(4) ?? '').replaceAll('\\', '/');
      results.add(<String, Object?>{
        'path': relativePath,
        'bytes': bytes,
        'megabytes': bytes / (1024 * 1024),
        'object': match.group(2),
        'source': 'history',
      });
    }
    return results;
  }

  bool _isGeneratedLargeFile(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/').toLowerCase();
    return normalized.startsWith('build/') ||
        normalized.contains('/build/') ||
        normalized.startsWith('.dart_tool/') ||
        normalized.contains('/.dart_tool/') ||
        normalized.endsWith('.pdb') ||
        normalized.endsWith('.ilk') ||
        normalized.endsWith('.obj');
  }

  Future<void> _updateGeneratedGitignore(String workspace) async {
    final gitignore = File(path.join(workspace, '.gitignore'));
    final existing = await gitignore.exists() ? await gitignore.readAsString() : '';
    final lines = existing.split(RegExp(r'\r?\n')).map((line) => line.trim()).toSet();
    final additions = <String>{
      'build/',
      '.dart_tool/',
      '*.pdb',
      '*.ilk',
      '*.obj',
    }.where((rule) => !lines.contains(rule)).toList();
    if (additions.isNotEmpty) {
      final suffix = existing.isEmpty || existing.endsWith('\n') ? '' : '\n';
      await gitignore.writeAsString('$existing$suffix${additions.join('\n')}\n');
    }
  }

  Future<void> _removePathsFromIndex(
    String workspace,
    Iterable<String> paths,
  ) async {
    for (final relativePath in paths.toSet()) {
      if (relativePath.trim().isEmpty) continue;
      final rm = await Process.run(
        'git',
        <String>['rm', '-r', '--cached', '--ignore-unmatch', '--', relativePath],
        workingDirectory: workspace,
        runInShell: true,
      );
      if (rm.exitCode != 0) {
        throw StateError('Súbor $relativePath sa nepodarilo odstrániť z Git indexu: ${rm.stderr.toString().trim()}');
      }
    }
  }

  Future<void> _repairOutgoingLargeFileHistory(
    String workspace,
    String branch,
    List<Map<String, Object?>> largeFiles, {
    required String commitMessage,
    required String changeDescription,
  }) async {
    final unsafe = largeFiles.where((item) => !_isGeneratedLargeFile('${item['path']}')).toList();
    if (unsafe.isNotEmpty) {
      final details = unsafe
          .map((item) => '${item['path']} (${(item['megabytes'] as num).toStringAsFixed(1)} MB)')
          .join(', ');
      throw StateError(
        'Odosielaná história obsahuje veľké používateľské súbory: $details. Použi Git LFS alebo ich odstráň ručne.',
      );
    }

    final baseRef = await _originBranchRef(workspace, branch);
    await _updateGeneratedGitignore(workspace);

    // Bezpečne zloží všetky lokálne neodoslané commity do jedného nového commitu
    // nad aktuálnou vzdialenou vetvou. Pracovné súbory na disku zostanú zachované.
    final reset = await Process.run(
      'git',
      <String>['reset', '--soft', baseRef],
      workingDirectory: workspace,
      runInShell: true,
    );
    if (reset.exitCode != 0) {
      throw StateError('Obnova histórie zlyhala pri soft reset: ${reset.stderr.toString().trim()}');
    }

    await _removePathsFromIndex(
      workspace,
      largeFiles.map((item) => '${item['path']}'),
    );

    final add = await Process.run(
      'git',
      <String>['add', '-A'],
      workingDirectory: workspace,
      runInShell: true,
    );
    if (add.exitCode != 0) {
      throw StateError('Príprava opraveného commitu zlyhala: ${add.stderr.toString().trim()}');
    }

    // Po git add -A ešte raz odstránime ignorované generované cesty z indexu.
    await _removePathsFromIndex(
      workspace,
      largeFiles.map((item) => '${item['path']}'),
    );

    final message = changeDescription.trim().isEmpty
        ? commitMessage.trim()
        : '${commitMessage.trim()}\n\n${changeDescription.trim()}';
    final commit = await Process.run(
      'git',
      <String>['commit', '-m', message],
      workingDirectory: workspace,
      runInShell: true,
    );
    if (commit.exitCode != 0) {
      throw StateError('Vytvorenie opraveného commitu zlyhalo: ${commit.stderr.toString().trim()}');
    }
  }

  Future<void> _runSmartGitPreflight(
    String workspace,
    String branch, {
    required String commitMessage,
    required String changeDescription,
    bool includeRemoteChecks = true,
  }) async {
    await _removeStaleGitIndexLock(workspace);
    _addLog('Git preflight: kontrola .gitignore');
    await _updateGeneratedGitignore(workspace);

    _addLog('Git preflight: kontrola sledovaných súborov nad 100 MB');
    final tracked = await _findTrackedLargeFiles(workspace);
    if (tracked.isNotEmpty) {
      final unsafe = tracked.where((item) => !_isGeneratedLargeFile('${item['path']}')).toList();
      if (unsafe.isNotEmpty) {
        final details = unsafe
            .map((item) => '${item['path']} (${(item['megabytes'] as num).toStringAsFixed(1)} MB)')
            .join(', ');
        throw StateError('Git sleduje veľké používateľské súbory: $details. Použi Git LFS alebo ich odstráň ručne.');
      }
      await _removePathsFromIndex(workspace, tracked.map((item) => '${item['path']}'));
      await Process.run('git', <String>['add', '.gitignore'], workingDirectory: workspace, runInShell: true);
      final amend = await Process.run(
        'git',
        <String>['commit', '--amend', '--no-edit'],
        workingDirectory: workspace,
        runInShell: true,
      );
      if (amend.exitCode != 0) {
        throw StateError('Oprava aktuálneho commitu zlyhala: ${amend.stderr.toString().trim()}');
      }
    }

    if (includeRemoteChecks) {
      _addLog('Git preflight: kontrola neodoslaných commitov');
      final outgoing = await _findOutgoingLargeBlobs(workspace, branch);
      if (outgoing.isNotEmpty) {
        await _repairOutgoingLargeFileHistory(
          workspace,
          branch,
          outgoing,
          commitMessage: commitMessage,
          changeDescription: changeDescription,
        );
      }
    } else {
      _addLog('Git preflight: origin nie je nastavený, vzdialené kontroly boli preskočené.');
    }

    _addLog('Git preflight: záverečné overenie');
    final remainingTracked = await _findTrackedLargeFiles(workspace);
    final remainingOutgoing = includeRemoteChecks
        ? await _findOutgoingLargeBlobs(workspace, branch)
        : <Map<String, Object?>>[];
    final remaining = <Map<String, Object?>>[...remainingTracked, ...remainingOutgoing];
    if (remaining.isNotEmpty) {
      final details = remaining
          .map((item) => '${item['path']} (${(item['megabytes'] as num).toStringAsFixed(1)} MB)')
          .toSet()
          .join(', ');
      throw StateError('Git preflight nedokázal odstrániť všetky veľké súbory: $details');
    }
  }

  Future<void> _executeBuildCompletion(Map<String, Object?> data) async {
    final workspace = (data['workspace'] as String?)?.trim() ?? '';
    final options = Map<String, bool>.from(data['options'] as Map? ?? const <String, bool>{});
    final results = <Map<String, Object?>>[];
    final progressText = ValueNotifier<String>('Pripravujem dokončenie buildu…');
    var progressDialogOpened = false;
    String? releaseZipPath;
    String? buildReportPath;
    String? githubCommitUrl;

    Future<void> openOutputPath(String targetPath) async {
      final target = File(targetPath);
      if (!await target.exists()) {
        throw StateError('Výstup už neexistuje: $targetPath');
      }
      await Process.start(
        'explorer.exe',
        <String>['/select,', target.path],
        runInShell: false,
      );
    }

    Future<void> openExternalUrl(String url) async {
      final result = await Process.run(
        'cmd.exe',
        <String>['/c', 'start', '', url],
        runInShell: false,
      );
      if (result.exitCode != 0) {
        throw StateError('Odkaz sa nepodarilo otvoriť: ${result.stderr}');
      }
    }

    Future<String?> resolveGithubCommitUrl() async {
      final remoteResult = await Process.run(
        'git',
        <String>['config', '--get', 'remote.origin.url'],
        workingDirectory: workspace,
        runInShell: true,
      );
      final hashResult = await Process.run(
        'git',
        <String>['rev-parse', 'HEAD'],
        workingDirectory: workspace,
        runInShell: true,
      );
      if (remoteResult.exitCode != 0 || hashResult.exitCode != 0) return null;

      var remote = remoteResult.stdout.toString().trim();
      final hash = hashResult.stdout.toString().trim();
      if (remote.isEmpty || hash.isEmpty) return null;

      if (remote.startsWith('git@github.com:')) {
        remote = 'https://github.com/${remote.substring('git@github.com:'.length)}';
      } else if (remote.startsWith('ssh://git@github.com/')) {
        remote = 'https://github.com/${remote.substring('ssh://git@github.com/'.length)}';
      }
      if (!remote.startsWith('https://github.com/')) return null;
      if (remote.endsWith('.git')) remote = remote.substring(0, remote.length - 4);
      return '$remote/commit/$hash';
    }

    if (mounted) {
      unawaited(
        showDialog<void>(
          context: context,
          useRootNavigator: true,
          barrierDismissible: false,
          builder: (dialogContext) {
            progressDialogOpened = true;
            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Row(
                  children: <Widget>[
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text('Dokončujem build')),
                  ],
                ),
                content: SizedBox(
                  width: 460,
                  child: ValueListenableBuilder<String>(
                    valueListenable: progressText,
                    builder: (context, value, child) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 10),
                        const Text('Okno sa po dokončení automaticky nahradí výsledkom.'),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    Future<void> step(String name, Future<void> Function() action) async {
      progressText.value = name;
      _addLog('Build Completion Center: ▶ $name');
      try {
        await action();
        results.add(<String, Object?>{'name': name, 'success': true, 'message': 'Hotovo'});
        _addLog('Build Completion Center: ✔ $name');
      } catch (error) {
        results.add(<String, Object?>{'name': name, 'success': false, 'message': '$error'});
        _addLog('Build Completion Center: ✖ $name: $error');
        rethrow;
      }
    }

    void skippedStep(String name, String message) {
      results.add(<String, Object?>{'name': name, 'success': true, 'message': message});
      _addLog('Build Completion Center: ↷ $name — $message');
    }

    try {
      if (options['commit'] == true) {
        await step('Git commit', () async {
          final result = await _gitService.commitAll(
            workspace,
            message: (data['commitMessage'] as String?)?.trim() ?? '',
          );
          if (!result.success) throw StateError(result.message);
        });
      }

      if (options['tag'] == true) {
        await step('Git tag', () async {
          final result = await _gitService.createTag(
            workspace,
            tagName: (data['tagName'] as String?)?.trim() ?? '',
            message: (data['commitMessage'] as String?)?.trim(),
          );
          if (!result.success) throw StateError(result.message);
        });
      }

      if (options['push'] == true) {
        final hasOrigin = await _gitRemoteExists(workspace);
        final branch = (data['branch'] as String?)?.trim();
        if (branch == null || branch.isEmpty) throw StateError('Git vetva nie je známa.');

        await step('Git preflight', () async {
          await _runSmartGitPreflight(
            workspace,
            branch,
            commitMessage: (data['commitMessage'] as String?)?.trim() ?? 'Build completion recovery',
            changeDescription: (data['changeDescription'] as String?)?.trim() ?? '',
            includeRemoteChecks: hasOrigin,
          ).timeout(
            const Duration(minutes: 3),
            onTimeout: () => throw TimeoutException(
              'Git preflight bol po 3 minútach bezpečne zastavený. Skontroluj živý log.',
            ),
          );
        });

        if (!hasOrigin) {
          skippedStep(
            'Git push',
            'Preskočené — vzdialený repozitár origin nie je nastavený. Commit a tag zostali bezpečne uložené lokálne.',
          );
        } else {
          await step('Git push', () async {
            final pushBranch = await Process.run(
              'git', <String>['push', '-u', 'origin', branch],
              workingDirectory: workspace, runInShell: true,
            );
            if (pushBranch.exitCode != 0) {
              throw StateError('Push vetvy zlyhal: ${pushBranch.stderr.toString().trim()}');
            }
            if (options['tag'] == true) {
              final tag = (data['tagName'] as String?)?.trim() ?? '';
              final pushTag = await Process.run(
                'git', <String>['push', 'origin', tag],
                workingDirectory: workspace, runInShell: true,
              );
              if (pushTag.exitCode != 0) {
                throw StateError('Push tagu zlyhal: ${pushTag.stderr.toString().trim()}');
              }
            }
          });
        }
      }

      if (options['exportZip'] == true) {
        await step('Export Release ZIP', () async {
          releaseZipPath = (await _createOneClickReleaseZip(workspace)).path;
        });
      }

      final rmDirectory = Directory(path.join(workspace, '.release_manager'));
      await rmDirectory.create(recursive: true);
      final completedAt = DateTime.now().toIso8601String();
      final completionRecord = <String, Object?>{
        ...data,
        'completedAt': completedAt,
        'releaseZip': releaseZipPath,
        'results': results,
      };

      if (options['buildReport'] == true) {
        await step('Build Report', () async {
          final reports = Directory(path.join(rmDirectory.path, 'build_completion_reports'));
          await reports.create(recursive: true);
          final build = data['build'];
          final report = File(path.join(reports.path, 'BUILD_${build}_COMPLETION_REPORT.md'));
          buildReportPath = report.path;
          final lines = <String>[
            '# Build Completion Report', '',
            '- Projekt: ${data['project']}',
            '- Verzia: ${data['version']}',
            '- Build: ${data['build']}',
            '- Vetva: ${data['branch']}',
            '- Dokončené: $completedAt', '',
            '## Commit Message', '', '${data['commitMessage']}', '',
            '## Popis zmien', '', '${data['changeDescription']}', '',
            '## Interné poznámky', '', '${data['internalNotes']}', '',
            '## Výsledky', '',
            ...results.map((r) => '- ${r['success'] == true ? 'OK' : 'CHYBA'}: ${r['name']} — ${r['message']}'),
          ];
          await report.writeAsString(lines.join('\n'));
        });
      }

      if (options['history'] == true) {
        await step('História buildov', () async {
          final file = File(path.join(rmDirectory.path, 'build_completion_history.json'));
          var history = <Object?>[];
          if (await file.exists()) {
            final decoded = jsonDecode(await file.readAsString());
            if (decoded is List) history = List<Object?>.from(decoded);
          }
          history.add(completionRecord);
          if (history.length > 100) history = history.sublist(history.length - 100);
          await file.writeAsString(const JsonEncoder.withIndent('  ').convert(history));
        });
      }

      if (options['synchronizeZip'] == true) {
        await step('Synchronizácia ZIP', () async {
          await _synchronizeDevelopmentZip();
        });
      }
    } catch (_) {
      // Zastavíme reťazec pri prvej chybe, aby sa nevytvoril neúplný release.
    }

    progressText.value = 'Obnovujem stav projektu…';
    try {
      await _refreshGitWorkspace().timeout(const Duration(seconds: 10));
    } catch (error) {
      _addLog('Build Completion Center: obnovenie Git stavu sa nepodarilo: $error');
    }
    try {
      githubCommitUrl = await resolveGithubCommitUrl();
    } catch (error) {
      _addLog('Build Completion Center: GitHub odkaz sa nepodarilo pripraviť: $error');
    }

    if (mounted && progressDialogOpened) {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) navigator.pop();
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    progressText.dispose();

    if (!mounted) return;
    final success = results.isNotEmpty && results.every((r) => r['success'] == true);
    try {
      await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(children: <Widget>[
          Icon(success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: success ? const Color(0xFF2E7D32) : Theme.of(context).colorScheme.error),
          const SizedBox(width: 10),
          Text(success ? 'Build bol dokončený' : 'Dokončenie buildu zlyhalo'),
        ]),
        content: SizedBox(
          width: 620,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: results.map((result) => ListTile(
              dense: true,
              leading: Icon(result['success'] == true ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: result['success'] == true ? const Color(0xFF2E7D32) : Theme.of(context).colorScheme.error),
              title: Text('${result['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${result['message']}'),
            )).toList(),
          ),
        ),
        actions: <Widget>[
          if (buildReportPath != null)
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await openOutputPath(buildReportPath!);
                } catch (error) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('$error')),
                  );
                }
              },
              icon: const Icon(Icons.description_rounded),
              label: const Text('BUILD REPORT'),
            ),
          if (releaseZipPath != null)
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await openOutputPath(releaseZipPath!);
                } catch (error) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('$error')),
                  );
                }
              },
              icon: const Icon(Icons.archive_rounded),
              label: const Text('RELEASE ZIP'),
            ),
          if (githubCommitUrl != null)
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await openExternalUrl(githubCommitUrl!);
                } catch (error) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('$error')),
                  );
                }
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('GITHUB COMMIT'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ZAVRIEŤ'),
          ),
        ],
      ),
    );
    } catch (error) {
      _addLog('Build Completion Center: výsledkové okno sa nepodarilo otvoriť: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Build bol dokončený. Výsledky sú zapísané v živom termináli.'
                : 'Dokončenie buildu zlyhalo. Podrobnosti sú v živom termináli.'),
          ),
        );
      }
    }
  }

Widget _buildSectionOverviewDashboard() {
    final managerSelected =
        _managerProjectPath != null && _managerProjectPath!.trim().isNotEmpty;
    final stavbySelected = _project != null;
    final apkReady = _apkPath != null;

    final sections = <({
      String title,
      String detail,
      IconData icon,
      Color color,
      int page,
      String status,
    })>[
      (
        title: 'Projekt',
        detail: stavbySelected
            ? '${_project!.projectName} • ${_project!.version}+${_project!.build}'
            : 'Výber a kontrola projektu STAVBY PRO',
        icon: Icons.folder_rounded,
        color: const Color(0xFFFF9800),
        page: 1,
        status: stavbySelected ? 'PRIPRAVENÝ' : 'NEVYBRANÝ',
      ),
      (
        title: 'APK',
        detail: apkReady
            ? path.basename(_apkPath!)
            : 'Build, analýza a export APK pre STAVBY PRO',
        icon: Icons.android_rounded,
        color: const Color(0xFF43A047),
        page: 2,
        status: apkReady ? 'PRIPRAVENÉ' : 'ČAKÁ',
      ),
      (
        title: 'WINDOWS',
        detail: _windowsZipExtracted
            ? path.basename(
                _windowsExtractedProjectPath ?? 'Windows DEV projekt',
              )
            : 'Samostatný Windows DEV build STAVBY PRO',
        icon: Icons.desktop_windows_rounded,
        color: const Color(0xFF1565C0),
        page: 3,
        status: _windowsZipExtracted ? 'NAČÍTANÝ' : 'PRIPRAVENÝ',
      ),
      (
        title: 'GitHub',
        detail: _githubConnected
            ? 'Repozitár je pripojený a pripravený na publikovanie'
            : 'Nastavenie repozitára, tokenu a publikovania',
        icon: Icons.cloud_rounded,
        color: const Color(0xFF00ACC1),
        page: 4,
        status: _githubConnected ? 'ONLINE' : 'NEPRIPOJENÝ',
      ),
      (
        title: 'Release Wizard – finálny workflow',
        detail: managerSelected
            ? path.basename(_managerProjectPath!)
            : 'Rozbaliť ZIP → Build → Export → Dokončiť vydanie → Test EXE',
        icon: Icons.rocket_launch_rounded,
        color: const Color(0xFF8E24AA),
        page: 5,
        status: managerSelected ? 'AKTÍVNY' : 'PRIPRAVENÝ',
      ),
      (
        title: 'Git Workspace',
        detail: _gitWorkspaceStatus?.isRepository == true
            ? '${_gitWorkspaceStatus!.branch} • ${_gitWorkspaceStatus!.changedFiles.length} zmien'
            : 'Lokálny Git stav, vetva a zmenené súbory',
        icon: Icons.account_tree_rounded,
        color: const Color(0xFF2E7D32),
        page: 6,
        status: _gitWorkspaceStatus?.isRepository == true
            ? 'AKTÍVNY'
            : 'PRIPRAVENÝ',
      ),
    ];

    Widget statusPill({
      required IconData icon,
      required String label,
      required bool ok,
    }) {
      final color = ok ? const Color(0xFF2E7D32) : const Color(0xFFF57C00);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const Key('sectionOverviewDashboard'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.tertiaryContainer,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(RMDesign.cardRadius),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'STAVBY PRO Release Manager',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      'Compact Desktop • Windows • Android • Git • Release',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  ReleaseManagerVersion.compact,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildProjectDashboardCard(),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              statusPill(
                icon: Icons.folder_rounded,
                label: stavbySelected ? 'Projekt OK' : 'Projekt nevybraný',
                ok: stavbySelected,
              ),
              const SizedBox(width: 6),
              statusPill(
                icon: Icons.android_rounded,
                label: apkReady ? 'APK pripravené' : 'APK čaká',
                ok: apkReady,
              ),
              const SizedBox(width: 6),
              statusPill(
                icon: Icons.desktop_windows_rounded,
                label: _managerBuildSucceeded ? 'Windows OK' : 'Windows čaká',
                ok: _managerBuildSucceeded,
              ),
              const SizedBox(width: 6),
              statusPill(
                icon: Icons.cloud_done_rounded,
                label: _githubConnected ? 'GitHub online' : 'GitHub offline',
                ok: _githubConnected,
              ),
              const SizedBox(width: 6),
              statusPill(
                icon: Icons.analytics_rounded,
                label: 'Analyze: $_lastAnalyzeErrors / $_lastAnalyzeWarnings / $_lastAnalyzeInfos',
                ok: _lastAnalyzeErrors == 0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RMSectionCard(
          title: '⚡ Rýchle akcie • Denný pracovný postup',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Najčastejšie používané kroky sú zoradené v odporúčanom poradí. Začni synchronizáciou ZIP-u a pokračuj až po uloženie buildu.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 840;
              Widget actionButton({
                required IconData icon,
                required String label,
                required String detail,
                required VoidCallback? onPressed,
                required Color color,
              }) {
                return SizedBox(
                  height: 92,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: onPressed,
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                          ),
                          child: Icon(icon, size: 24),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                detail,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white.withValues(alpha: 0.86),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                );
              }

              final actions = <Widget>[
                actionButton(
                  icon: Icons.folder_zip_rounded,
                  label: '1. SYNCHRONIZOVAŤ ZIP',
                  detail: 'Načíta nový vývojový build do workspace.',
                  onPressed: _workspaceSyncRunning ? null : _synchronizeDevelopmentZip,
                  color: const Color(0xFF1565C0),
                ),
                actionButton(
                  icon: Icons.rocket_launch_rounded,
                  label: '2. SPUSTIŤ CELÝ BUILD',
                  detail: _oneClickBuildRunning ? 'Prebieha: $_oneClickBuildCurrentStep' : 'Analyze, test a Windows Release build.',
                  onPressed: _gitWorkspaceStatus?.isRepository == true && !_oneClickBuildRunning ? _runOneClickBuild : null,
                  color: const Color(0xFF8E24AA),
                ),
                actionButton(
                  icon: Icons.play_circle_fill_rounded,
                  label: '3. OTESTOVAŤ EXE',
                  detail: 'Spustí posledný úspešný Windows build.',
                  onPressed: _managerBuildSucceeded && _gitWorkspacePath != null
                      ? () => _launchOneClickWindowsBuild(_gitWorkspacePath!)
                      : null,
                  color: const Color(0xFFF57C00),
                ),
                actionButton(
                  icon: Icons.save_alt_rounded,
                  label: '4. ULOŽIŤ BUILD',
                  detail: 'Commit, tag a push cez Git Developer Center.',
                  onPressed: _gitWorkspaceStatus?.isRepository == true ? _showBuildCompletionCenter : null,
                  color: const Color(0xFF2E7D32),
                ),
              ];

              if (compact) {
                return Column(
                  children: actions.expand((item) => <Widget>[item, const SizedBox(height: 8)]).toList()..removeLast(),
                );
              }
              return Row(
                children: <Widget>[
                  for (var i = 0; i < actions.length; i++) ...<Widget>[
                    Expanded(child: actions[i]),
                    if (i != actions.length - 1) const SizedBox(width: 8),
                  ],
                ],
              );
            },
          ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _busy ? null : () => setState(() => _selectedPage = 5),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: <Widget>[
                  const _ColorIcon(
                    icon: Icons.rocket_launch_rounded,
                    color: Color(0xFF8E24AA),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'VYTVORIŤ NOVÝ RELEASE',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Windows, APK, AAB, report a export v jednom workflow.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF8E24AA),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text('ROZŠÍRENÉ MODULY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
        ),
        RMAdaptiveGrid(
          itemHeight: 126,
          children: sections.map((section) {
            return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => setState(() => _selectedPage = section.page),
                      child: Padding(
                        padding: const EdgeInsets.all(11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                _ColorIcon(
                                  icon: section.icon,
                                  color: section.color,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    section.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: section.color.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    section.status,
                                    style: TextStyle(
                                      color: section.color,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                section.detail,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Row(
                              children: <Widget>[
                                Text(
                                  'OTVORIŤ',
                                  style: TextStyle(
                                    color: section.color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: section.color,
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final projectCard = RMSectionCard(
              title: '📋 Aktívny projekt',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _project == null
                        ? 'Projekt STAVBY PRO zatiaľ nie je načítaný.'
                        : '${_project!.projectName} • ${_project!.version}+${_project!.build}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _project?.projectPath ?? 'Vyber projekt v sekcii Projekt.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _selectedPage = 1),
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: const Text('OTVORIŤ PROJEKT'),
                  ),
                ],
              ),
            );
            final analyzerCard = RMSectionCard(
              title: '🧠 Flutter Analyze',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SegmentedButton<bool>(
                    segments: const <ButtonSegment<bool>>[
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.verified_rounded),
                        label: Text('Professional'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.gpp_maybe_rounded),
                        label: Text('Strict'),
                      ),
                    ],
                    selected: <bool>{_strictAnalyzeMode},
                    onSelectionChanged: _busy
                        ? null
                        : (selection) => setState(
                              () => _strictAnalyzeMode = selection.first,
                            ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '$_lastAnalyzeStatus • chyby $_lastAnalyzeErrors • warning $_lastAnalyzeWarnings • info $_lastAnalyzeInfos',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
            if (compact) {
              return Column(
                children: <Widget>[
                  projectCard,
                  const SizedBox(height: 8),
                  analyzerCard,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: projectCard),
                const SizedBox(width: 8),
                Expanded(child: analyzerCard),
              ],
            );
          },
        ),
      ],
    );
  }


  Widget _buildSettingsHelpCenterPage() {
    Widget settingGroup({
      required IconData icon,
      required Color color,
      required String title,
      required String description,
      required List<Widget> actions,
    }) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(RMDesign.cardRadius),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(description),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      );
    }

    Widget helpTopic({
      required IconData icon,
      required String title,
      required String text,
      int? page,
    }) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(text),
                  ],
                ),
              ),
              if (page != null)
                IconButton(
                  tooltip: 'Otvoriť modul',
                  onPressed: () => setState(() => _selectedPage = page),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      key: const Key('settingsHelpCenterPage'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RMSectionCard(
          title: '⚙️ Nastavenia a pomoc',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Najčastejšie nastavenia a stručné návody sú na jednom mieste. '
                'Pokročilé technické voľby zostávajú v príslušných moduloch.',
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final groups = <Widget>[
                    settingGroup(
                      icon: Icons.palette_outlined,
                      color: const Color(0xFF5C6BC0),
                      title: 'Vzhľad a ovládanie',
                      description: 'Téma aplikácie a klávesové skratky.',
                      actions: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () async {
                            final dark = appThemeMode.value != ThemeMode.dark;
                            appThemeMode.value = dark ? ThemeMode.dark : ThemeMode.light;
                            await const AppSettingsService().saveDarkMode(dark);
                          },
                          icon: const Icon(Icons.contrast_rounded),
                          label: const Text('PREPNÚŤ TÉMU'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _showKeyboardShortcutsDialog,
                          icon: const Icon(Icons.keyboard_alt_outlined),
                          label: const Text('KLÁVESOVÉ SKRATKY'),
                        ),
                      ],
                    ),
                    settingGroup(
                      icon: Icons.folder_copy_outlined,
                      color: const Color(0xFFFF9800),
                      title: 'Projekt a workspace',
                      description: 'Výber projektu, synchronizácia ZIP a obnovenie stavu.',
                      actions: <Widget>[
                        OutlinedButton.icon(
                          onPressed: _gitWorkspaceLoading ? null : _chooseGitWorkspace,
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('VYBRAŤ WORKSPACE'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _workspaceSyncRunning ? null : _synchronizeDevelopmentZip,
                          icon: const Icon(Icons.folder_zip_rounded),
                          label: const Text('SYNCHRONIZOVAŤ ZIP'),
                        ),
                      ],
                    ),
                    settingGroup(
                      icon: Icons.cloud_outlined,
                      color: const Color(0xFF00ACC1),
                      title: 'Git a GitHub',
                      description: 'Pripojenie, commit, tag, push a publikovanie verzií.',
                      actions: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _selectedPage = 6),
                          icon: const Icon(Icons.account_tree_rounded),
                          label: const Text('GIT CENTER'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _selectedPage = 4),
                          icon: const Icon(Icons.cloud_rounded),
                          label: const Text('GITHUB A AKTUALIZÁCIE'),
                        ),
                      ],
                    ),
                    settingGroup(
                      icon: Icons.build_circle_outlined,
                      color: const Color(0xFF1565C0),
                      title: 'Build a diagnostika',
                      description: 'Windows build, Release Wizard a diagnostické výstupy.',
                      actions: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _selectedPage = 3),
                          icon: const Icon(Icons.desktop_windows_rounded),
                          label: const Text('WINDOWS BUILD'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _selectedPage = 5),
                          icon: const Icon(Icons.rocket_launch_rounded),
                          label: const Text('RELEASE WIZARD'),
                        ),
                      ],
                    ),
                  ];
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: groups
                          .expand((item) => <Widget>[item, const SizedBox(height: 10)])
                          .toList()
                        ..removeLast(),
                    );
                  }
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.55,
                    children: groups,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RMSectionCard(
          title: '❓ Centrum pomoci',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              helpTopic(
                icon: Icons.looks_one_rounded,
                title: 'Prvý build',
                text: 'Vyber workspace, synchronizuj vývojový ZIP cez „Zálohovať a synchronizovať“ a potom spusti celý build.',
                page: 0,
              ),
              const SizedBox(height: 8),
              helpTopic(
                icon: Icons.folder_zip_rounded,
                title: 'Synchronizácia ZIP',
                text: 'Tlačidlo Zrušiť synchronizáciu nevykoná. Pre aktualizáciu workspace vždy potvrď „Zálohovať a synchronizovať“.',
                page: 1,
              ),
              const SizedBox(height: 8),
              helpTopic(
                icon: Icons.rocket_launch_rounded,
                title: 'Quick Build',
                text: 'Release Wizard rozbalí ZIP, automaticky načíta projekt a spustí Windows build. Ručný výber adresára zostáva dostupný.',
                page: 5,
              ),
              const SizedBox(height: 8),
              helpTopic(
                icon: Icons.account_tree_rounded,
                title: 'Uloženie buildu do Gitu',
                text: 'Po úspešnom teste aplikácie otvor Git Developer Center a použi „Uložiť build do Gitu“. Vykoná commit, tag a push.',
                page: 6,
              ),
              const SizedBox(height: 8),
              helpTopic(
                icon: Icons.psychology_rounded,
                title: 'Project Analyzer',
                text: 'Analyzer zobrazí reálne moduly, obrazovky, služby, databázové tabuľky a TODO/FIXME položky projektu.',
                page: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RMSectionCard(
          title: '🩺 Rýchla diagnostika',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _gitWorkspaceLoading ? null : _refreshGitWorkspace,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('OBNOVIŤ STAV PROJEKTU'),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _selectedPage = 10),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('OTVORIŤ ANALYZER'),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _selectedPage = 8),
                icon: const Icon(Icons.schema_rounded),
                label: const Text('OTVORIŤ PIPELINE'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectNavigationPage(int index) {
    if (index < 0 || index > 11 || _selectedPage == index) return;
    setState(() => _selectedPage = index);
    unawaited(
      _appSettingsService.saveNavigationState(
        selectedPage: index,
        developerMode: _developerMode,
      ),
    );
  }

  void _selectPageFromShortcut(int index) {
    if (_busy || index < 0 || index > 11 || _selectedPage == index) return;
    _selectNavigationPage(index);
  }

  Future<void> _showKeyboardShortcutsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.keyboard_alt_outlined, color: Color(0xFF7E57C2)),
        title: const Text('Klávesové skratky'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Ctrl + 1  –  Dashboard'),
            SizedBox(height: 8),
            Text('Ctrl + 2  –  Projekt'),
            SizedBox(height: 8),
            Text('Ctrl + 3  –  APK'),
            SizedBox(height: 8),
            Text('Ctrl + 4  –  WINDOWS'),
            SizedBox(height: 8),
            Text('Ctrl + 5  –  GitHub'),
            SizedBox(height: 8),
            Text('Ctrl + 6  –  Release Wizard'),
            SizedBox(height: 8),
            Text('Ctrl + 7  –  Git'),
            SizedBox(height: 8),
            Text('Ctrl + 8  –  Plugin Center'),
            Text('Ctrl + 9  –  Release Pipeline'),
          ],
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ZAVRIEŤ'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionLabel(BuildContext context, String label) {
    if (_sidebarCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Divider(
          indent: 18,
          endIndent: 18,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 5),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    Key? key,
  }) {
    final selected = _selectedPage == index;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 550),
        child: Material(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(12),
            onTap: () => _selectNavigationPage(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: _sidebarCollapsed ? 8 : 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: selected
                    ? Border(left: BorderSide(color: color, width: 4))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: _sidebarCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: color, size: 21),
                  ),
                  if (!_sidebarCollapsed) ...<Widget>[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedSidebar(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: _sidebarCollapsed ? 82 : 286,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                _sidebarCollapsed ? 8 : 16,
                10,
                _sidebarCollapsed ? 8 : 16,
                8,
              ),
              child: _sidebarCollapsed
                  ? Center(
                      child: IconButton(
                        tooltip: 'Rozbaliť menu',
                        onPressed: () => setState(() => _sidebarCollapsed = false),
                        icon: const Icon(
                          Icons.keyboard_double_arrow_right_rounded,
                          size: 22,
                        ),
                      ),
                    )
                  : Row(
                      children: <Widget>[
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            Icons.apartment_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Release Manager',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                _developerMode
                                    ? 'Rozšírená navigácia'
                                    : 'Jednoduchá navigácia',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Zbaliť menu',
                          onPressed: () => setState(() => _sidebarCollapsed = true),
                          icon: const Icon(
                            Icons.keyboard_double_arrow_left_rounded,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Klávesové skratky',
                          onPressed: _showKeyboardShortcutsDialog,
                          icon: const Icon(Icons.keyboard_alt_outlined, size: 20),
                        ),
                      ],
                    ),
            ),
            const Divider(height: 1),
            if (!_sidebarCollapsed)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      padding: const WidgetStatePropertyAll<EdgeInsets>(
                        EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                      ),
                      textStyle: const WidgetStatePropertyAll<TextStyle>(
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    segments: const <ButtonSegment<bool>>[
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.auto_awesome_rounded, size: 16),
                        label: Text('Jednoduchý', maxLines: 1, overflow: TextOverflow.fade),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.developer_mode_rounded, size: 16),
                        label: Text('Rozšírený', maxLines: 1, overflow: TextOverflow.fade),
                      ),
                    ],
                    selected: <bool>{_developerMode},
                    onSelectionChanged: (selection) {
                      final developer = selection.first;
                      setState(() {
                        _developerMode = developer;
                        if (!developer && <int>{4, 7, 8, 9, 10}.contains(_selectedPage)) {
                          _selectedPage = 0;
                        }
                      });
                      unawaited(
                        _appSettingsService.saveNavigationState(
                          selectedPage: _selectedPage,
                          developerMode: _developerMode,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _developerMode
                        ? 'Rozšírený režim zobrazuje všetky vývojové a servisné nástroje.'
                        : 'Jednoduchý režim zobrazuje iba najčastejšie používané pracovné kroky.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.25,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 12),
                children: <Widget>[
                  _buildSidebarSectionLabel(context, 'Prehľad'),
                  _buildSidebarItem(context, index: 0, icon: Icons.dashboard_rounded, label: 'Dashboard', color: const Color(0xFF1976D2), key: const Key('navDashboard')),
                  _buildSidebarSectionLabel(context, 'Projekt'),
                  _buildSidebarItem(context, index: 1, icon: Icons.folder_rounded, label: 'Projekt a workspace', color: const Color(0xFFFF9800), key: const Key('navProject')),
                  if (_developerMode)
                    _buildSidebarItem(context, index: 10, icon: Icons.psychology_rounded, label: 'Project Analyzer', color: const Color(0xFF5E35B1), key: const Key('navProjectAnalyzer')),
                  _buildSidebarSectionLabel(context, 'Build a vydanie'),
                  _buildSidebarItem(context, index: 2, icon: Icons.android_rounded, label: 'Android APK', color: const Color(0xFF43A047), key: const Key('navApk')),
                  _buildSidebarItem(context, index: 3, icon: Icons.desktop_windows_rounded, label: 'Windows Build', color: const Color(0xFF1565C0), key: const Key('navWindows')),
                  _buildSidebarItem(context, index: 5, icon: Icons.rocket_launch_rounded, label: 'Release Wizard', color: const Color(0xFF8E24AA), key: const Key('navTools')),
                  if (_developerMode)
                    _buildSidebarItem(context, index: 8, icon: Icons.schema_rounded, label: 'Release Pipeline', color: const Color(0xFF6A1B9A), key: const Key('navPipeline')),
                  _buildSidebarSectionLabel(context, 'Git a publikovanie'),
                  _buildSidebarItem(context, index: 6, icon: Icons.account_tree_rounded, label: _developerMode ? 'Git Developer Center' : 'Uložiť build do Gitu', color: const Color(0xFF2E7D32), key: const Key('navGit')),
                  if (_developerMode)
                    _buildSidebarItem(context, index: 4, icon: Icons.cloud_rounded, label: 'GitHub a aktualizácie', color: const Color(0xFF00ACC1), key: const Key('navGithub')),
                  if (_developerMode) ...<Widget>[
                    _buildSidebarSectionLabel(context, 'Pokročilé nástroje'),
                    _buildSidebarItem(context, index: 7, icon: Icons.extension_rounded, label: 'Plugin Center', color: const Color(0xFFE65100), key: const Key('navPlugins')),
                    _buildSidebarItem(context, index: 9, icon: Icons.hub_rounded, label: 'Vzdialení agenti', color: const Color(0xFF00897B), key: const Key('navRemoteAgents')),
                  ],
                  _buildSidebarSectionLabel(context, _developerMode ? 'Nastavenia' : 'Pomoc'),
                  _buildSidebarItem(
                    context,
                    index: 11,
                    icon: Icons.help_center_rounded,
                    label: _developerMode ? 'Nastavenia a pomoc' : 'Pomoc a nastavenia',
                    color: const Color(0xFF546E7A),
                    key: const Key('navSettingsHelp'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(_sidebarCollapsed ? 8 : 12),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(_sidebarCollapsed ? 8 : 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      _project == null ? Icons.info_outline_rounded : Icons.check_circle_rounded,
                      size: 17,
                      color: _project == null
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : const Color(0xFF43A047),
                    ),
                    if (!_sidebarCollapsed) ...<Widget>[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _project == null
                              ? 'Projekt nie je vybraný'
                              : '${_project!.projectName}\n${_project!.version} • Build ${_project!.build}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => _selectPageFromShortcut(0),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => _selectPageFromShortcut(1),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => _selectPageFromShortcut(2),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => _selectPageFromShortcut(3),
        const SingleActivator(LogicalKeyboardKey.digit5, control: true): () => _selectPageFromShortcut(4),
        const SingleActivator(LogicalKeyboardKey.digit6, control: true): () => _selectPageFromShortcut(5),
        const SingleActivator(LogicalKeyboardKey.digit7, control: true): () => _selectPageFromShortcut(6),
        const SingleActivator(LogicalKeyboardKey.digit8, control: true): () => _selectPageFromShortcut(7),
        const SingleActivator(LogicalKeyboardKey.digit9, control: true): () => _selectPageFromShortcut(8),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      key: const Key('releaseManagerPage'),
      appBar: AppBar(
        toolbarHeight: 56,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('STAVBY PRO Release Manager'),
            const SizedBox(height: 2),
            Text(
              'Profesionálna príprava a publikovanie verzií',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Klávesové skratky',
            onPressed: _showKeyboardShortcutsDialog,
            icon: const Icon(Icons.keyboard_alt_outlined),
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: appThemeMode,
            builder: (context, mode, _) => IconButton(
              tooltip: mode == ThemeMode.dark ? 'Zapnúť svetlý režim' : 'Zapnúť tmavý režim',
              onPressed: () async {
                final dark = mode != ThemeMode.dark;
                appThemeMode.value = dark ? ThemeMode.dark : ThemeMode.light;
                await const AppSettingsService().saveDarkMode(dark);
              },
              icon: Icon(
                mode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: mode == ThemeMode.dark ? const Color(0xFFFFC107) : const Color(0xFF5C6BC0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  ReleaseManagerVersion.badge,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: <Widget>[
          _buildGroupedSidebar(context),
          const VerticalDivider(width: 1),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1600),
                child: ListView(
            padding: RMDesign.pagePadding,
            children: <Widget>[
              if (_selectedPage == 0) _buildSectionOverviewDashboard(),
              if (_selectedPage == 10) _buildProjectAnalyzerPage(),
              if (_selectedPage == 11) _buildSettingsHelpCenterPage(),
              if (_selectedPage == 1)
                const SizedBox(height: 16),
              if (_selectedPage == 1)
                RMSectionCard(
                  title: 'Project Profiles',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _projectProfilesLoading
                                ? const LinearProgressIndicator()
                                : DropdownButtonFormField<String>(
                                    initialValue: _activeProjectProfileId,
                                    decoration: const InputDecoration(
                                      labelText: 'Aktívny projekt',
                                      prefixIcon: Icon(Icons.account_tree_rounded),
                                    ),
                                    hint: const Text('Vyber uložený profil'),
                                    items: _projectProfiles
                                        .map((profile) => DropdownMenuItem<String>(
                                              value: profile.id,
                                              child: Text(profile.name),
                                            ))
                                        .toList(),
                                    onChanged: _busy
                                        ? null
                                        : (id) async {
                                            if (id == null) return;
                                            final profile = _projectProfiles.firstWhere((item) => item.id == id);
                                            await _activateProjectProfile(profile);
                                          },
                                  ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: _busy ? null : _createProjectProfile,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('NOVÝ PROFIL'),
                          ),
                        ],
                      ),
                      if (_projectProfiles.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        ..._projectProfiles.map((profile) {
                          final active = profile.id == _activeProjectProfileId;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                active ? Icons.check_circle_rounded : Icons.folder_copy_rounded,
                                color: active ? const Color(0xFF43A047) : const Color(0xFF1976D2),
                              ),
                              title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                '${profile.projectPath}\n${profile.platforms.isEmpty ? 'Platformy: nezistené' : 'Platformy: ${profile.platforms.join(', ')}'} • Branch: ${profile.gitBranch.trim().isEmpty ? 'auto' : profile.gitBranch}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              isThreeLine: false,
                              onTap: _busy ? null : () => _activateProjectProfile(profile),
                              trailing: PopupMenuButton<String>(
                                tooltip: 'Správa profilu',
                                onSelected: (action) async {
                                  if (action == 'rename') await _renameProjectProfile(profile);
                                  if (action == 'branch') await _editProjectProfileBranch(profile);
                                  if (action == 'duplicate') await _duplicateProjectProfile(profile);
                                  if (action == 'delete') await _deleteProjectProfile(profile);
                                },
                                itemBuilder: (_) => const <PopupMenuEntry<String>>[
                                  PopupMenuItem(value: 'rename', child: Text('Premenovať')),
                                  PopupMenuItem(value: 'branch', child: Text('Git vetva')),
                                  PopupMenuItem(value: 'duplicate', child: Text('Duplikovať')),
                                  PopupMenuItem(value: 'delete', child: Text('Odstrániť')),
                                ],
                              ),
                            ),
                          );
                        }),
                      ] else if (!_projectProfilesLoading) ...<Widget>[
                        const SizedBox(height: 10),
                        const Text('Zatiaľ nemáš uložený profil. Klikni na NOVÝ PROFIL a vyber projekt.'),
                      ],
                    ],
                  ),
                ),
              if (_selectedPage == 1)
                const SizedBox(height: 16),
              if (_selectedPage == 1)
                _buildLocalBuildAssistant(),
              if (_selectedPage == 1)
                const SizedBox(height: 16),
              if (_selectedPage == 1)
                _buildSnapshotCenter(),
              if (_selectedPage == 1)
                const SizedBox(height: 16),
              if (_selectedPage == 1)
                RMSectionCard(
                title: 'Projekt STAVBY PRO',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    FilledButton.icon(
                      key: const Key('projectPickerButton'),
                      onPressed: _busy ? null : _pickProject,
                      icon: const Icon(Icons.folder_open),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('VYBRAŤ PRIEČINOK PROJEKTU'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Projekt', value: project?.projectName ?? 'Nevybraný'),
                    _InfoRow(label: 'Cesta', value: project?.projectPath ?? '—'),
                    _InfoRow(label: 'Verzia', value: project?.version ?? '—'),
                    _InfoRow(label: 'Build Flutter', value: project?.build.toString() ?? '—'),
                    _InfoRow(label: 'Build OTA', value: project?.releaseBuild.toString() ?? '—'),
                  ],
                ),
              ),
              if (_selectedPage == 1)
                const SizedBox(height: 16),
              if (_selectedPage == 1)
                RMSectionCard(
                  title: 'Naposledy použité projekty',
                  child: _recentProjectPaths.isEmpty
                      ? const Text('Po otvorení projektu sa tu zobrazia rýchle odkazy na posledných 6 projektov.')
                      : Column(
                          children: _recentProjectPaths.map((projectPath) {
                            final isActive = project?.projectPath == projectPath;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFFF9800).withValues(alpha: 0.10)
                                    : Theme.of(context).colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFFFF9800).withValues(alpha: 0.55)
                                      : Theme.of(context).colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  _ColorIcon(
                                    icon: isActive ? Icons.folder_special_rounded : Icons.folder_copy_rounded,
                                    color: isActive ? const Color(0xFFFF9800) : const Color(0xFF1976D2),
                                    selected: isActive,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          path.basename(projectPath),
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          projectPath,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isActive)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(Icons.check_circle_rounded, color: Color(0xFF43A047)),
                                    )
                                  else
                                    IconButton(
                                      tooltip: 'Otvoriť projekt',
                                      onPressed: _busy ? null : () async {
                                        if (await _recentProjectExists(projectPath)) {
                                          await _openProjectPath(projectPath);
                                        } else {
                                          if (!mounted) return;
                                          _showError('Priečinok projektu už neexistuje: $projectPath');
                                        }
                                      },
                                      icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF43A047)),
                                    ),
                                  IconButton(
                                    tooltip: 'Odstrániť zo zoznamu',
                                    onPressed: _busy ? null : () => _removeRecentProject(projectPath),
                                    icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFE53935)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              if (_selectedPage == 1)
                const SizedBox(height: 16),
              if (_selectedPage == 2)
                const SizedBox(height: 16),
              if (_selectedPage == 2)
                _buildAndroidWorkspaceCompactOverview(),
              if (_selectedPage == 2)
                const SizedBox(height: 12),
              if (_selectedPage == 2)
                RMSectionCard(
                  title: '📱 STAVBY PRO – ANDROID',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const _ColorIcon(
                            icon: Icons.verified_user_rounded,
                            color: Color(0xFF43A047),
                            selected: true,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Kontrola Android prostredia',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  project == null
                                      ? 'Najprv vyber alebo rozbaľ projekt STAVBY PRO.'
                                      : _projectChecks.isEmpty
                                          ? 'Pred buildom over Flutter SDK, Android projekt a povinné súčasti.'
                                          : '${_projectChecks.where((item) => item.status == _CheckStatus.ok).length} z ${_projectChecks.length} kontrol je úspešných.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _busy || project == null ? null : _checkProjectReadiness,
                            icon: const Icon(Icons.fact_check_rounded),
                            label: const Text('OVERIŤ ANDROID PROJEKT'),
                          ),
                        ],
                      ),
                      if (_projectChecks.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 14),
                        ..._projectChecks.map((item) {
                          final isOk = item.status == _CheckStatus.ok;
                          final isWarning = item.status == _CheckStatus.warning;
                          final color = isOk
                              ? const Color(0xFF43A047)
                              : isWarning
                                  ? const Color(0xFFF9A825)
                                  : item.status == _CheckStatus.checking
                                      ? const Color(0xFF1976D2)
                                      : Theme.of(context).colorScheme.error;
                          final icon = isOk
                              ? Icons.check_circle_rounded
                              : isWarning
                                  ? Icons.warning_amber_rounded
                                  : item.status == _CheckStatus.checking
                                      ? Icons.sync_rounded
                                      : Icons.error_rounded;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Icon(icon, color: color, size: 20),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    item.label,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item.detail,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              if (_selectedPage == 2)
                const SizedBox(height: 12),
              if (_selectedPage == 2)
                _WorkflowQuickActions(
                  accent: const Color(0xFF43A047),
                  actions: <_WorkflowQuickActionData>[
                    _WorkflowQuickActionData(
                      title: 'Spustiť APK build',
                      subtitle: 'Kompletný build APK',
                      icon: Icons.android_rounded,
                      onPressed: _busy || _project == null ? null : _runFullBuild,
                    ),
                    _WorkflowQuickActionData(
                      title: 'Build APK + AAB',
                      subtitle: 'Kompletný Android release',
                      icon: Icons.inventory_2_rounded,
                      onPressed: _busy || _project == null ? null : _runFullBuild,
                    ),
                    _WorkflowQuickActionData(
                      title: 'Export APK',
                      subtitle: 'Exportovať hotové APK',
                      icon: Icons.file_upload_rounded,
                      onPressed: _busy || _apkSha256 == null ? null : _exportAndroidRelease,
                    ),
                    _WorkflowQuickActionData(
                      title: 'Analýza APK',
                      subtitle: 'Skontrolovať APK',
                      icon: Icons.manage_search_rounded,
                      onPressed: _busy || project == null ? null : _analyzeApk,
                    ),
                    _WorkflowQuickActionData(
                      title: 'História buildov',
                      subtitle: 'Zobraziť históriu',
                      icon: Icons.history_rounded,
                      onPressed: project == null ? null : _showReleaseHistoryDialog,
                    ),
                  ],
                ),
              if (_selectedPage == 2)
                const SizedBox(height: 12),
              if (_selectedPage == 2)
                RMSectionCard(
                  title: 'Android APK Workflow',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Kompletný postup výroby Android verzie STAVBY PRO. '
                        'Jednotlivé kroky môžeš spustiť samostatne alebo použiť kompletný build.',
                      ),
                      const SizedBox(height: 16),
                      _ApkWorkflowStep(
                        number: 1,
                        title: 'Rozbaliť ZIP projektu',
                        detail: _androidZipExtracted
                            ? 'Rozbalené: ${_androidExtractedProjectPath ?? 'projekt STAVBY PRO'}'
                            : 'Vyber ZIP novej verzie STAVBY PRO. Po rozbalení sa projekt automaticky načíta.',
                        completed: _androidZipExtracted,
                        active: _zipExtracting,
                        action: FilledButton.icon(
                          onPressed: _busy || _zipExtracting ? null : _openAndExtractAndroidZip,
                          icon: _zipExtracting
                              ? const SizedBox.square(dimension: 17, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.folder_zip_rounded),
                          label: Text(_zipExtracting ? 'ROZBAĽUJEM...' : 'ROZBALIŤ ZIP'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        number: 2,
                        title: 'Vybrať projekt STAVBY PRO',
                        detail: project == null
                            ? 'Projekt ešte nie je vybraný.'
                            : '${project.projectName} • ${project.fullVersion}',
                        completed: project != null,
                        action: FilledButton.icon(
                          onPressed: _busy ? null : _pickProject,
                          icon: const Icon(Icons.folder_open_rounded),
                          label: Text(project == null ? 'VYBRAŤ PROJEKT' : 'ZMENIŤ PROJEKT'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        number: 3,
                        title: 'Skontrolovať verziu a build',
                        detail: project == null
                            ? 'Po výbere projektu sa načíta verzia a build.'
                            : 'Verzia ${project.version} • Flutter build ${project.build} • OTA build ${project.releaseBuild}',
                        completed: project != null,
                        action: OutlinedButton.icon(
                          onPressed: _busy || project == null ? null : () => setState(() => _selectedPage = 1),
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('OTVORIŤ PROJEKT'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        number: 4,
                        title: 'Flutter clean',
                        detail: 'Vyčistí predchádzajúce build výstupy.',
                        completed: _completedApkBuildSteps.contains('Flutter clean'),
                        active: _activeCommand == 'Flutter clean',
                        action: OutlinedButton(
                          onPressed: _busy || project == null ? null : () => _runFlutterCommand(<String>['clean'], label: 'Flutter clean'),
                          child: const Text('CLEAN'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        number: 4,
                        title: 'Flutter pub get',
                        detail: _flutterStepDetail(label: 'Flutter pub get', idleText: 'Načíta závislosti projektu.'),
                        completed: _completedApkBuildSteps.contains('Flutter pub get'),
                        active: _activeCommand == 'Flutter pub get',
                        progress: _flutterStepProgress('Flutter pub get'),
                        action: OutlinedButton(
                          onPressed: _busy || project == null ? null : () => _runFlutterCommand(<String>['pub', 'get'], label: 'Flutter pub get'),
                          child: const Text('PUB GET'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        number: 6,
                        title: 'Flutter analyze',
                        detail: _flutterStepDetail(label: 'Flutter analyze', idleText: 'Skontroluje chyby a upozornenia v zdrojovom kóde.'),
                        completed: _completedApkBuildSteps.contains('Flutter analyze'),
                        active: _activeCommand == 'Flutter analyze',
                        progress: _flutterStepProgress('Flutter analyze'),
                        action: OutlinedButton(
                          onPressed: _busy || project == null ? null : () => _runFlutterCommand(<String>['analyze'], label: 'Flutter analyze'),
                          child: const Text('ANALYZE'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        number: 7,
                        title: 'Flutter test',
                        detail: _flutterStepDetail(label: 'Flutter test', idleText: 'Spustí automatické testy projektu.'),
                        completed: _completedApkBuildSteps.contains('Flutter test'),
                        active: _activeCommand == 'Flutter test',
                        progress: _flutterStepProgress('Flutter test'),
                        action: OutlinedButton(
                          onPressed: _busy || project == null ? null : () => _runFlutterCommand(<String>['test'], label: 'Flutter test'),
                          child: const Text('TEST'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        number: 8,
                        title: 'Vytvoriť Release APK',
                        detail: _flutterStepDetail(
                          label: 'Release APK build',
                          idleText: 'Spustí flutter build apk --release. Počas buildu zobrazí odhadovaný priebeh.',
                        ),
                        completed: _completedApkBuildSteps.contains('Release APK build'),
                        active: _activeCommand == 'Release APK build',
                        progress: _flutterStepProgress('Release APK build'),
                        action: OutlinedButton(
                          onPressed: _busy || project == null
                              ? null
                              : () => _runFlutterCommand(<String>['build', 'apk', '--release'], label: 'Release APK build'),
                          child: const Text('BUILD APK'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        number: 9,
                        title: 'Vytvoriť Release AAB',
                        detail: _aabPath == null
                            ? 'Spustí flutter build appbundle --release pre Google Play.'
                            : '${path.basename(_aabPath!)} • ${_formatMb(_aabSizeBytes!)} MB',
                        completed: _aabPath != null && _aabSha256 != null,
                        active: _activeCommand == 'Release AAB build',
                        action: OutlinedButton(
                          onPressed: _busy || project == null
                              ? null
                              : () async {
                                  final ok = await _runFlutterCommand(<String>['build', 'appbundle', '--release'], label: 'Release AAB build');
                                  if (ok) await _analyzeAab();
                                },
                          child: const Text('BUILD AAB'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        number: 10,
                        title: 'Overiť vytvorené APK',
                        detail: _apkPath == null
                            ? 'Po builde sa overí názov, veľkosť a SHA-256.'
                            : '${path.basename(_apkPath!)} • ${_formatMb(_apkSizeBytes!)} MB',
                        completed: _apkPath != null && _apkSha256 != null,
                        active: _activeCommand == 'Analýza APK',
                        action: OutlinedButton.icon(
                          onPressed: _busy || project == null ? null : _analyzeApk,
                          icon: const Icon(Icons.verified_rounded),
                          label: const Text('OVERIŤ APK'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        number: 11,
                        title: 'Pripraviť Android Release',
                        detail: 'Doplň Release Notes a version.json pre Update Center.',
                        completed: _releaseNotesPreview != null && _versionJsonPreview != null,
                        action: OutlinedButton.icon(
                          onPressed: project == null ? null : () {},
                          icon: const Icon(Icons.description_rounded),
                          label: const Text('NIŽŠIE NA STRÁNKE'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        number: 12,
                        title: 'Export Android Release',
                        detail: _androidExportedApkPath == null
                            ? 'Skopíruje APK do samostatného Android Release priečinka. Windows Export Release zostáva nezávislý.'
                            : 'Exportované: ${path.basename(_androidExportedApkPath!)}',
                        completed: _androidExportedApkPath != null,
                        active: _activeCommand == 'Export Android Release',
                        action: FilledButton.icon(
                          onPressed: _busy || _apkSha256 == null ? null : _exportAndroidRelease,
                          icon: const Icon(Icons.file_upload_outlined),
                          label: const Text('EXPORT RELEASE'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        number: 13,
                        title: 'Otvoriť výsledné APK',
                        detail: 'Otvorí Prieskumník a označí vytvorený APK súbor.',
                        completed: _apkPath != null,
                        action: OutlinedButton.icon(
                          onPressed: _busy || _apkPath == null ? null : _openApkFolder,
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('OTVORIŤ APK'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        number: 14,
                        title: 'GitHub Release (voliteľné)',
                        detail: 'Publikovanie Android APK zostáva samostatným voliteľným krokom v sekcii GitHub.',
                        action: OutlinedButton.icon(
                          onPressed: () => setState(() => _selectedPage = 3),
                          icon: const Icon(Icons.cloud_upload_rounded),
                          label: const Text('OTVORIŤ GITHUB'),
                        ),
                      ),

                    ],
                  ),
                ),
              if (_selectedPage == 2)
                const SizedBox(height: 16),
              if (_selectedPage == 2)
                RMSectionCard(
                  title: 'Android Release – exportný priečinok',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Tento priečinok je určený iba pre Export Android Release. '
                        'Je uložený samostatne a nijako nemení Windows Export Release ani GitHub nastavenia.',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.android_rounded),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SelectableText(
                                _androidReleaseExportDirectory == null || _androidReleaseExportDirectory!.trim().isEmpty
                                    ? 'Samostatný Android Release priečinok nie je nastavený.'
                                    : _androidReleaseExportDirectory!,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _chooseAndroidReleaseExportDirectory,
                          icon: const Icon(Icons.drive_folder_upload_outlined),
                          label: Text(
                            _androidReleaseExportDirectory == null || _androidReleaseExportDirectory!.trim().isEmpty
                                ? 'VYBRAŤ ANDROID PRIEČINOK'
                                : 'ZMENIŤ ANDROID PRIEČINOK',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_selectedPage == 2)
                const SizedBox(height: 16),
              if (_selectedPage == 2)
                RMSectionCard(
                title: 'APK Manager',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _InfoRow(
                      label: 'APK',
                      value: _apkPath == null ? 'Neanalyzované' : path.basename(_apkPath!),
                    ),
                    _InfoRow(label: 'Cesta', value: _apkPath ?? '—'),
                    _InfoRow(
                      label: 'Veľkosť',
                      value: _apkSizeBytes == null
                          ? '—'
                          : '${_apkSizeBytes!} B (${_formatMb(_apkSizeBytes!)} MB)',
                    ),
                    _InfoRow(label: 'SHA-256 APK', value: _apkSha256 ?? '—'),
                    const Divider(height: 24),
                    _InfoRow(label: 'AAB', value: _aabPath == null ? 'Neanalyzované' : path.basename(_aabPath!)),
                    _InfoRow(label: 'Cesta AAB', value: _aabPath ?? '—'),
                    _InfoRow(label: 'Veľkosť AAB', value: _aabSizeBytes == null ? '—' : '${_formatMb(_aabSizeBytes!)} MB'),
                    _InfoRow(label: 'SHA-256 AAB', value: _aabSha256 ?? '—'),
                    const SizedBox(height: 14),
                    _buildGitHubOperationProgress(),
                    if (_githubOperationTitle != null) const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: _busy || project == null ? null : _analyzeApk,
                          icon: const Icon(Icons.search),
                          label: const Text('NÁJSŤ A ANALYZOVAŤ APK'),
                        ),
                        FilledButton.icon(
                          onPressed: _busy || _apkSha256 == null ? null : _copyApkData,
                          icon: const Icon(Icons.copy),
                          label: const Text('KOPÍROVAŤ ÚDAJE'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_selectedPage == 2)
                const SizedBox(height: 16),
              if (_selectedPage == 2)
                RMSectionCard(
                title: 'Version JSON',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Builder(
                      builder: (context) {
                        final value = _apkUrlController.text.trim();
                        final isEmpty = value.isEmpty;
                        final isValid = !isEmpty && _isValidApkUrl(value);
                        return TextField(
                          controller: _apkUrlController,
                          enabled: !_busy && project != null,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: 'URL release APK (nepovinné)',
                            hintText: 'https://github.com/.../releases/download/v3.6.0/STAVBY_PRO_3.6.0_MOBILE_UI_84.apk',
                            helperText: isEmpty
                                ? 'URL môžeš doplniť až po nahratí APK na GitHub.'
                                : isValid
                                    ? 'Platná URL APK.'
                                    : 'URL musí začínať http:// alebo https:// a končiť na .apk.',
                            prefixIcon: Icon(
                              isEmpty
                                  ? Icons.warning_amber_rounded
                                  : isValid
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                            ),
                            suffixIcon: IconButton(
                              tooltip: 'Vložiť zo schránky',
                              onPressed: _busy || project == null ? null : _pasteApkUrl,
                              icon: const Icon(Icons.content_paste),
                            ),
                          ),
                          onChanged: (_) => setState(() => _versionJsonPreview = null),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: _busy || _apkSha256 == null
                              ? null
                              : _generateVersionJsonPreview,
                          icon: const Icon(Icons.data_object),
                          label: const Text('VYGENEROVAŤ NÁHĽAD'),
                        ),
                        FilledButton.icon(
                          onPressed: _busy || _apkSha256 == null
                              ? null
                              : _saveVersionJson,
                          icon: const Icon(Icons.save_alt),
                          label: const Text('ULOŽIŤ VERSION.JSON'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy || _apkSha256 == null
                              ? null
                              : _copyVersionJson,
                          icon: const Icon(Icons.copy),
                          label: const Text('KOPÍROVAŤ JSON'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      constraints: const BoxConstraints(minHeight: 120),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        _versionJsonPreview ??
                            'Po analýze APK môžeš version.json vytvoriť aj bez URL. URL doplníš po nahratí APK na GitHub.',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),

              if (_selectedPage == 2)
                const SizedBox(height: 16),
              if (_selectedPage == 2)
                RMSectionCard(
                title: 'Release Notes',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextField(
                      controller: _newsController,
                      enabled: !_busy && project != null,
                      minLines: 3,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Novinky',
                        hintText: 'Každú novinku napíš na samostatný riadok.',
                        alignLabelWithHint: true,
                      ),
                      onChanged: (_) => setState(() => _releaseNotesPreview = null),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fixesController,
                      enabled: !_busy && project != null,
                      minLines: 3,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Opravy',
                        hintText: 'Každú opravu napíš na samostatný riadok.',
                        alignLabelWithHint: true,
                      ),
                      onChanged: (_) => setState(() => _releaseNotesPreview = null),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: _busy || project == null
                              ? null
                              : _generateReleaseNotesPreview,
                          icon: const Icon(Icons.preview),
                          label: const Text('NÁHĽAD RELEASE NOTES'),
                        ),
                        FilledButton.icon(
                          onPressed: _busy || project == null
                              ? null
                              : _saveReleaseNotes,
                          icon: const Icon(Icons.save_alt),
                          label: const Text('ULOŽIŤ RELEASE_NOTES.MD'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy || project == null
                              ? null
                              : _copyReleaseNotes,
                          icon: const Icon(Icons.copy),
                          label: const Text('KOPÍROVAŤ MARKDOWN'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      constraints: const BoxConstraints(minHeight: 150),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        _releaseNotesPreview ??
                            'Sem sa zobrazí Markdown náhľad Release Notes s verziou a aktuálnym dátumom.',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),

              if (_selectedPage == 0)
                const SizedBox(height: 16),

              if (_selectedPage == 3)
                _WorkflowQuickActions(
                  accent: const Color(0xFF1565C0),
                  actions: <_WorkflowQuickActionData>[
                    _WorkflowQuickActionData(
                      title: 'Spustiť Windows Workspace',
                      subtitle: 'Kontrola + kompletný build',
                      icon: Icons.desktop_windows_rounded,
                      onPressed: _busy || project == null ? null : _runFullWindowsDevBuild,
                    ),
                    _WorkflowQuickActionData(
                      title: 'Export Windows',
                      subtitle: 'Exportovať Windows Release',
                      icon: Icons.file_upload_rounded,
                      onPressed: _busy ||
                              _windowsBuiltExePath == null ||
                              !_windowsWorkspace.completedBuildSteps.contains('Spustenie Windows EXE')
                          ? null
                          : _exportWindowsDevRelease,
                    ),
                    _WorkflowQuickActionData(
                      title: 'Analýza Windows',
                      subtitle: 'Flutter analyze',
                      icon: Icons.manage_search_rounded,
                      onPressed: _busy || project == null
                          ? null
                          : () => _runWindowsFlutterCommand(
                                <String>['analyze'],
                                label: 'Windows Flutter analyze',
                              ),
                    ),
                    _WorkflowQuickActionData(
                      title: 'Test EXE',
                      subtitle: 'Spustiť hotovú aplikáciu',
                      icon: Icons.play_circle_rounded,
                      onPressed: _busy || _windowsBuiltExePath == null ? null : _launchWindowsDevExe,
                    ),
                  ],
                ),
              if (_selectedPage == 3)
                const SizedBox(height: 12),
              if (_selectedPage == 3)
                RMSectionCard(
                  title: 'STAVBY PRO – WINDOWS',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const _ColorIcon(
                            icon: Icons.desktop_windows_rounded,
                            color: Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Windows DEV Workflow',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Samostatný Windows postup oddelený od Android APK. '
                                  'Kompletný build zobrazuje každý krok rovnako prehľadne ako APK workflow. '
                                  'EXE sa považuje za úspešne spustené iba vtedy, keď zostane bežať aspoň 5 sekúnd.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildWindowsWorkspaceCompactOverview(),
                      const SizedBox(height: 12),
                      _buildWindowsEnvironmentPanel(),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _busy || project == null ? null : _runFullWindowsDevBuild,
                        icon: const Icon(Icons.rocket_launch_rounded),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 13),
                          child: Text('SPUSTIŤ KOMPLETNÝ WINDOWS WORKSPACE'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ApkWorkflowStep(
                        accent: const Color(0xFF1565C0),
                        number: 1,
                        title: 'Rozbaliť ZIP Windows DEV projektu',
                        detail: _windowsZipExtracted
                            ? 'Rozbalené: ${_windowsExtractedProjectPath ?? 'Windows DEV projekt'}'
                            : 'Vyber ZIP Windows DEV projektu STAVBY PRO. Projekt sa po rozbalení automaticky načíta.',
                        completed: _windowsZipExtracted,
                        active: _zipExtracting,
                        action: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: _busy || _zipExtracting ? null : _openAndExtractWindowsZip,
                              icon: _zipExtracting
                                  ? const SizedBox.square(
                                      dimension: 17,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.folder_zip_rounded),
                              label: Text(_zipExtracting ? 'ROZBAĽUJEM...' : 'ROZBALIŤ WINDOWS ZIP'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _busy || _zipExtracting ? null : _openExistingWindowsProject,
                              icon: const Icon(Icons.folder_open_rounded),
                              label: const Text('OTVORIŤ PROJEKT'),
                            ),
                          ],
                        ),
                      ),
                      _ApkWorkflowStep(
                        accent: const Color(0xFF1565C0),
                        number: 2,
                        title: 'Flutter clean',
                        detail: _windowsFlutterStepDetail(
                          label: 'Windows Flutter clean',
                          idleText: 'Vyčistí predchádzajúce Windows build výstupy.',
                        ),
                        completed: _windowsWorkspace.completedBuildSteps.contains('Windows Flutter clean'),
                        active: _activeCommand == 'Windows Flutter clean',
                        progress: _windowsFlutterStepProgress('Windows Flutter clean'),
                        action: OutlinedButton(
                          onPressed: _busy || project == null
                              ? null
                              : () => _runWindowsFlutterCommand(
                                    <String>['clean'],
                                    label: 'Windows Flutter clean',
                                  ),
                          child: const Text('CLEAN'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        accent: const Color(0xFF1565C0),
                        number: 3,
                        title: 'Vyčistiť Windows Flutter ephemeral',
                        detail: _activeCommand == 'Vyčistenie Windows ephemeral'
                            ? 'Odstraňujem windows\\flutter\\ephemeral...'
                            : _windowsWorkspace.completedBuildSteps.contains('Vyčistenie Windows ephemeral')
                                ? 'Windows Flutter ephemeral je čistý.'
                                : 'Odstráni staré generované plugin symlinky pred novým buildom.',
                        completed: _windowsWorkspace.completedBuildSteps.contains('Vyčistenie Windows ephemeral'),
                        active: _activeCommand == 'Vyčistenie Windows ephemeral',
                        action: OutlinedButton.icon(
                          onPressed: _busy || project == null ? null : _cleanWindowsEphemeralStep,
                          icon: const Icon(Icons.delete_sweep_rounded),
                          label: const Text('VYČISTIŤ'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        accent: const Color(0xFF1565C0),
                        number: 4,
                        title: 'Flutter pub get',
                        detail: _windowsFlutterStepDetail(
                          label: 'Windows Flutter pub get',
                          idleText: 'Načíta závislosti Windows DEV projektu.',
                        ),
                        completed: _windowsWorkspace.completedBuildSteps.contains('Windows Flutter pub get'),
                        active: _activeCommand == 'Windows Flutter pub get',
                        progress: _windowsFlutterStepProgress('Windows Flutter pub get'),
                        action: OutlinedButton(
                          onPressed: _busy || project == null
                              ? null
                              : () => _runWindowsFlutterCommand(
                                    <String>['pub', 'get'],
                                    label: 'Windows Flutter pub get',
                                  ),
                          child: const Text('PUB GET'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        accent: const Color(0xFF1565C0),
                        number: 5,
                        title: 'Flutter analyze',
                        detail: _windowsFlutterStepDetail(
                          label: 'Windows Flutter analyze',
                          idleText: 'Skontroluje zdrojový kód pred Windows buildom.',
                        ),
                        completed: _windowsWorkspace.completedBuildSteps.contains('Windows Flutter analyze'),
                        active: _activeCommand == 'Windows Flutter analyze',
                        progress: _windowsFlutterStepProgress('Windows Flutter analyze'),
                        action: OutlinedButton.icon(
                          onPressed: _busy || project == null
                              ? null
                              : () => _runWindowsFlutterCommand(
                                    <String>['analyze'],
                                    label: 'Windows Flutter analyze',
                                  ),
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('ANALYZE'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        accent: const Color(0xFF1565C0),
                        number: 6,
                        title: 'Flutter build windows --release',
                        detail: _windowsFlutterStepDetail(
                          label: 'Windows Release build',
                          idleText: 'Zostaví Windows DEV aplikáciu. Počas buildu zobrazuje odhadovaný priebeh.',
                        ),
                        completed: _windowsWorkspace.completedBuildSteps.contains('Windows Release build'),
                        active: _activeCommand == 'Windows Release build',
                        progress: _windowsFlutterStepProgress('Windows Release build'),
                        action: OutlinedButton.icon(
                          onPressed: _busy || project == null ? null : _buildWindowsReleaseStep,
                          icon: const Icon(Icons.window_rounded),
                          label: const Text('BUILD WINDOWS'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        accent: const Color(0xFF1565C0),
                        number: 7,
                        title: 'Overiť stavby_pro_dev.exe',
                        detail: _windowsBuiltExePath == null
                            ? 'Po builde overí, či stavby_pro_dev.exe skutočne existuje vo výstupe.'
                            : 'EXE nájdené: $_windowsBuiltExePath',
                        completed: _windowsWorkspace.completedBuildSteps.contains('Kontrola Windows EXE'),
                        active: _activeCommand == 'Kontrola Windows EXE',
                        action: OutlinedButton.icon(
                          onPressed: _busy || project == null ? null : _verifyWindowsDevExeStep,
                          icon: const Icon(Icons.verified_rounded),
                          label: const Text('OVERIŤ EXE'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        accent: const Color(0xFF1565C0),
                        number: 8,
                        title: 'Spustiť a otestovať stavby_pro_dev.exe',
                        detail: _windowsLaunchStatus,
                        completed: _windowsWorkspace.completedBuildSteps.contains('Spustenie Windows EXE'),
                        active: _activeCommand == 'Spustenie Windows EXE',
                        action: FilledButton.icon(
                          onPressed: _busy || _windowsBuiltExePath == null
                              ? null
                              : _launchWindowsDevExe,
                          icon: const Icon(Icons.play_circle_fill_rounded),
                          label: const Text('SPUSTIŤ EXE'),
                        ),
                      ),
                      _ApkWorkflowStep(
                        accent: const Color(0xFF1565C0),
                        number: 9,
                        title: 'Export Windows Release',
                        detail: _windowsExportedPath == null
                            ? 'Skopíruje celý hotový Windows build do nastaveného exportného priečinka.'
                            : 'Exportované: $_windowsExportedPath',
                        completed: _windowsExportedPath != null,
                        active: _activeCommand == 'Export Windows Release',
                        action: FilledButton.icon(
                          onPressed: _busy ||
                                  _windowsBuiltExePath == null ||
                                  !_windowsWorkspace.completedBuildSteps.contains('Spustenie Windows EXE')
                              ? null
                              : _exportWindowsDevRelease,
                          icon: const Icon(Icons.file_upload_rounded),
                          label: const Text('EXPORT RELEASE'),
                        ),
                      ),

                    ],
                  ),
                ),

              if (_selectedPage == 3)
                const SizedBox(height: 16),
              if (_selectedPage == 3)
                _buildBuildHistoryPanel(),
              if (_selectedPage == 3)
                const SizedBox(height: 16),
              if (_selectedPage == 3)
                _buildWindowsWorkspaceSummary(),
              if (_selectedPage == 3)
                const SizedBox(height: 16),

              if (_selectedPage == 3)
                RMSectionCard(
                  title: 'Nastavenie Windows Export Release',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Vyber vlastný cieľový priečinok pre export hotovej Windows aplikácie STAVBY PRO. '
                        'Toto nastavenie je nezávislé od Android APK aj od Release Manager exportu '
                        'a zostane uložené po reštarte aplikácie.',
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.drive_folder_upload_rounded),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SelectableText(
                                _appSettingsLoading
                                    ? 'Načítavam nastavenie...'
                                    : (_windowsReleaseExportDirectory == null ||
                                            _windowsReleaseExportDirectory!.trim().isEmpty)
                                        ? 'Windows Export Release priečinok nie je nastavený.'
                                        : _windowsReleaseExportDirectory!,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: _appSettingsLoading
                              ? null
                              : _chooseWindowsReleaseExportDirectory,
                          icon: const Icon(Icons.folder_open_rounded),
                          label: Text(
                            _windowsReleaseExportDirectory == null ||
                                    _windowsReleaseExportDirectory!.trim().isEmpty
                                ? 'VYBRAŤ EXPORT PRIEČINOK'
                                : 'ZMENIŤ EXPORT PRIEČINOK',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_selectedPage == 3)
                const SizedBox(height: 16),

              if (_selectedPage == 4)
                RMSectionCard(
                  title: 'GitHub Release Center',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          _StatusChip(
                            icon: _githubTesting
                                ? Icons.sync_rounded
                                : _githubConnected
                                    ? Icons.cloud_done_rounded
                                    : Icons.cloud_off_rounded,
                            label: _githubTesting
                                ? 'GitHub: kontrolujem'
                                : _githubConnected
                                    ? 'GitHub: online'
                                    : 'GitHub: nepripojený',
                            color: _githubTesting
                                ? const Color(0xFF1976D2)
                                : _githubConnected
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFC62828),
                          ),
                          _StatusChip(
                            icon: _managerUpdateDownloading
                                ? Icons.downloading_rounded
                                : Icons.system_update_alt_rounded,
                            label: _managerUpdateDownloading
                                ? 'Aktualizácia: sťahujem'
                                : 'Aktualizácia: pripravená',
                            color: _managerUpdateDownloading
                                ? const Color(0xFF1976D2)
                                : const Color(0xFF546E7A),
                          ),
                          _StatusChip(
                            icon: _githubPublishing
                                ? Icons.sync_rounded
                                : Icons.new_releases_rounded,
                            label: _githubPublishing
                                ? 'Release: publikujem'
                                : 'Release: čaká',
                            color: _githubPublishing
                                ? const Color(0xFF1976D2)
                                : const Color(0xFF7B1FA2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Na jednej obrazovke nastavíš pripojenie, skontroluješ aktualizácie a publikuješ celé vydanie. Bežný postup je zoradený zhora nadol.',
                      ),
                    ],
                  ),
                ),

              if (_selectedPage == 4)
                const SizedBox(height: 16),

              if (_selectedPage == 4)
                RMSectionCard(
                  title: 'Aktualizácie Release Managera',
                  child: Column(
                    key: const Key('managerUpdateDirectorySettings'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Určuje, kam sa budú ukladať aktualizačné ZIP balíky '
                        'Release Managera. Nastavenie zostane uložené aj po '
                        'reštarte aplikácie.',
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.folder_outlined),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SelectableText(
                                _appSettingsLoading
                                    ? 'Načítavam nastavenie...'
                                    : (_managerUpdateDownloadDirectory == null ||
                                            _managerUpdateDownloadDirectory!
                                                .trim()
                                                .isEmpty)
                                        ? 'Predvolený priečinok nie je nastavený.'
                                        : _managerUpdateDownloadDirectory!,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          key: const Key('chooseManagerUpdateDirectoryButton'),
                          onPressed: _appSettingsLoading ||
                                  _managerUpdateDownloading
                              ? null
                              : _chooseManagerUpdateDirectory,
                          icon: const Icon(Icons.drive_folder_upload_outlined),
                          label: Text(
                            _managerUpdateDownloadDirectory == null ||
                                    _managerUpdateDownloadDirectory!
                                        .trim()
                                        .isEmpty
                                ? 'VYBRAŤ PRIEČINOK'
                                : 'ZMENIŤ PRIEČINOK',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_selectedPage == 4)
                const SizedBox(height: 16),

              if (_selectedPage == 4)
                RMSectionCard(
                title: '1. GitHub pripojenie',
                child: Column(
                  key: const Key('githubConnectionPanel'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Nastav prístup k repozitáru pre budúce automatické publikovanie. Token sa neukladá do projektu ani do ZIP archívu; vo Windows je chránený cez DPAPI pre aktuálneho používateľa.',
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _githubOwnerController,
                      enabled: !_githubSettingsLoading &&
                          !_githubTesting &&
                          !_githubUpdatingVersionJson,
                      decoration: const InputDecoration(
                        labelText: 'GitHub vlastník (owner)',
                        hintText: 'marekmoravansky42',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _githubRepositoryController,
                      enabled: !_githubSettingsLoading &&
                          !_githubTesting &&
                          !_githubUpdatingVersionJson,
                      decoration: const InputDecoration(
                        labelText: 'Názov repozitára',
                        hintText: 'stavby-pro-updates',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('githubTokenField'),
                      controller: _githubTokenController,
                      enabled: !_githubSettingsLoading &&
                          !_githubTesting &&
                          !_githubUpdatingVersionJson,
                      obscureText: !_githubTokenVisible,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Fine-grained Personal Access Token',
                        prefixIcon: const Icon(Icons.key),
                        suffixIcon: IconButton(
                          tooltip: _githubTokenVisible ? 'Skryť token' : 'Zobraziť token',
                          onPressed: () => setState(
                            () => _githubTokenVisible = !_githubTokenVisible,
                          ),
                          icon: Icon(
                            _githubTokenVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            _githubTesting
                                ? Icons.sync
                                : _githubConnected
                                    ? Icons.check_circle
                                    : Icons.info_outline,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_githubStatus)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        FilledButton.icon(
                          key: const Key('githubTestButton'),
                          onPressed: _githubSettingsLoading ||
                                  _githubTesting ||
                                  _githubUpdatingVersionJson ||
                                  _githubCreatingRelease ||
                                  _githubUploadingApk ||
                                  _githubPublishing
                              ? null
                              : _saveAndTestGitHubConnection,
                          icon: _githubTesting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.link),
                          label: Text(_githubTesting
                              ? 'TESTUJEM PRIPOJENIE'
                              : 'ULOŽIŤ A OTESTOVAŤ PRIPOJENIE'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _githubSettingsLoading ||
                                  _githubTesting ||
                                  _githubUpdatingVersionJson ||
                                  _githubCreatingRelease ||
                                  _githubUploadingApk ||
                                  _githubPublishing
                              ? null
                              : _clearGitHubSettings,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('ODSTRÁNIŤ ULOŽENÉ PRIPOJENIE'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      '2. Publikovať celé vydanie',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Odporúčaný postup: jedným krokom aktualizuje version.json, vytvorí alebo použije GitHub Release a nahrá pripravené APK.',
                    ),
                    if (_githubOperationTitle != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildGitHubOperationProgress(),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('githubPublishButton'),
                      onPressed: !_githubConnected ||
                              _githubTesting ||
                              _githubUpdatingVersionJson ||
                              _githubCreatingRelease ||
                              _githubUploadingApk ||
                              _githubPublishing ||
                              project == null ||
                              _apkPath == null ||
                              _apkSha256 == null
                          ? null
                          : _publishToGitHub,
                      icon: _githubPublishing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.rocket_launch_outlined),
                      label: Text(
                        _githubPublishing
                            ? 'PUBLIKUJEM NA GITHUB'
                            : 'PUBLIKOVAŤ CELÉ VYDANIE',
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (project != null)
                      Text(
                        'Výsledný názov APK: ${_publishedApkName(project)}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      '3. Aktualizovať version.json samostatne',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Po potvrdení aplikácia nahradí súbor version.json v koreňovom priečinku repozitára údajmi z aktuálne pripraveného vydania. APK ani GitHub Release zatiaľ nenahráva.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('githubUpdateVersionJsonButton'),
                      onPressed: !_githubConnected ||
                              _githubTesting ||
                              _githubUpdatingVersionJson ||
                              project == null ||
                              _apkSha256 == null
                          ? null
                          : _updateVersionJsonOnGitHub,
                      icon: _githubUpdatingVersionJson
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(
                        _githubUpdatingVersionJson
                            ? 'AKTUALIZUJEM VERSION.JSON'
                            : 'AKTUALIZOVAŤ VERSION.JSON NA GITHUBE',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pred zápisom sa vždy zobrazí presný obsah a vyžaduje sa ručné potvrdenie.',
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      '4. Vytvoriť GitHub Release samostatne',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vytvorí tag a verejný GitHub Release s názvom a textom z pripraveného vydania. Pred vytvorením skontroluje, či Release s rovnakým tagom už neexistuje.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('githubCreateReleaseButton'),
                      onPressed: !_githubConnected ||
                              _githubTesting ||
                              _githubUpdatingVersionJson ||
                              _githubCreatingRelease ||
                              _githubUploadingApk ||
                              project == null ||
                              _apkSha256 == null
                          ? null
                          : _createGitHubRelease,
                      icon: _githubCreatingRelease
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.new_releases_outlined),
                      label: Text(
                        _githubCreatingRelease
                            ? 'VYTVÁRAM GITHUB RELEASE'
                            : 'VYTVORIŤ GITHUB RELEASE',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pred vytvorením sa vždy zobrazí tag, názov a celý text vydania na ručné potvrdenie.',
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      '5. Nahrať APK samostatne',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nahrá analyzované APK ako prílohu do už vytvoreného GitHub Release. Pred nahratím skontroluje tag, existenciu Release aj duplicitný názov súboru.',
                    ),
                    if (_githubOperationTitle != null && !_githubPublishing) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildGitHubOperationProgress(),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('githubUploadApkButton'),
                      onPressed: !_githubConnected ||
                              _githubTesting ||
                              _githubUpdatingVersionJson ||
                              _githubCreatingRelease ||
                              _githubUploadingApk ||
                              project == null ||
                              _apkPath == null ||
                              _apkSha256 == null
                          ? null
                          : _uploadApkToGitHubRelease,
                      icon: _githubUploadingApk
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_outlined),
                      label: Text(
                        _githubUploadingApk
                            ? 'NAHRÁVAM APK'
                            : 'NAHRAŤ APK DO GITHUB RELEASE',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pri rovnakom názve aplikácia ponúkne bezpečné nahradenie existujúceho APK.',
                    ),
                  ],
                ),
              ),
              if (_selectedPage == 4)
                const SizedBox(height: 16),
              if (_selectedPage == 4)
                RMSectionCard(
                title: 'Release poznámky a exportné súbory',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Vytvorí text pripravený na vloženie do GitHub Release. Použije údaje z APK a položky z Release Notes.',
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: _busy || project == null || _apkSha256 == null
                              ? null
                              : _generateGithubReleasePreview,
                          icon: const Icon(Icons.preview),
                          label: const Text('NÁHĽAD GITHUB RELEASE'),
                        ),
                        FilledButton.icon(
                          onPressed: _busy || project == null || _apkSha256 == null
                              ? null
                              : _saveGithubRelease,
                          icon: const Icon(Icons.save_alt),
                          label: const Text('ULOŽIŤ GITHUB_RELEASE.TXT'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy || project == null || _apkSha256 == null
                              ? null
                              : _copyGithubRelease,
                          icon: const Icon(Icons.copy),
                          label: const Text('KOPÍROVAŤ RELEASE TEXT'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      constraints: const BoxConstraints(minHeight: 180),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        _githubReleasePreview ??
                            'Sem sa zobrazí text pripravený pre GitHub Release.',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedPage == 5)
                RMSectionCard(
                  title: 'Release Wizard 3.0 – STAVBY PRO',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.30),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            const _ColorIcon(
                              icon: Icons.auto_awesome_rounded,
                              color: Color(0xFF7C3AED),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    _releaseWizardRunning
                                        ? 'Krok $_releaseWizardStep z ${_releaseWizardPipelineSteps.length}'
                                        : _releaseWizardStatus,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _project == null
                                        ? 'Najprv otvor projekt STAVBY PRO v Android alebo Windows Workspace.'
                                        : '${_project!.projectName} • ${_project!.fullVersion}',
                                  ),
                                  if (_releaseWizardRunning) ...<Widget>[
                                    const SizedBox(height: 5),
                                    Text(
                                      _releaseWizardStatus,
                                      style: const TextStyle(
                                        color: Color(0xFF6D28D9),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _releaseWizardRunning || _project == null
                                  ? null
                                  : _runReleaseWizard3,
                              icon: _releaseWizardRunning
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.rocket_launch_rounded),
                              label: Text(_releaseWizardRunning ? 'PREBIEHA...' : 'SPUSTIŤ WIZARD 3.0'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _releaseWizardRunning
                            ? (_releaseWizardStep / _releaseWizardPipelineSteps.length).clamp(0.0, 1.0)
                            : (_releaseWizardCompletedSteps.isEmpty ? 0 : 1),
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF7C3AED),
                      ),
                      const SizedBox(height: 8),
                      _ReleaseWizardPipeline(
                        steps: _releaseWizardPipelineSteps,
                        completedSteps: _releaseWizardCompletedSteps,
                        currentStep: _releaseWizardStatus,
                        running: _releaseWizardRunning,
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 760 ? 3 : 1;
                          final spacing = 10.0;
                          final width = (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: <Widget>[
                              _ReleaseArtifactCard(
                                width: width,
                                title: 'Windows EXE',
                                path: _windowsBuiltExePath,
                                icon: Icons.desktop_windows_rounded,
                              ),
                              _ReleaseArtifactCard(
                                width: width,
                                title: 'Android APK',
                                path: _apkPath,
                                icon: Icons.android_rounded,
                              ),
                              _ReleaseArtifactCard(
                                width: width,
                                title: 'Android AAB',
                                path: _aabPath,
                                icon: Icons.inventory_2_rounded,
                              ),
                            ],
                          );
                        },
                      ),
                      if (_releaseWizardReportPath != null || _releaseWizardReleaseDirectory != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              if (_releaseWizardReportPath != null)
                                SelectableText(
                                  'Report: $_releaseWizardReportPath',
                                  style: const TextStyle(fontFamily: 'monospace'),
                                ),
                              if (_releaseWizardReportPath != null && _releaseWizardReleaseDirectory != null)
                                const SizedBox(height: 8),
                              if (_releaseWizardReleaseDirectory != null)
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: SelectableText(
                                        'Release: $_releaseWizardReleaseDirectory',
                                        style: const TextStyle(fontFamily: 'monospace'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton.icon(
                                      onPressed: _openReleaseWizardDirectory,
                                      icon: const Icon(Icons.folder_open_rounded),
                                      label: const Text('OTVORIŤ RELEASE'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (_selectedPage == 5)
                const SizedBox(height: 16),
              if (_selectedPage == 5)
                _WorkflowQuickActions(
                  accent: const Color(0xFF7C3AED),
                  actions: <_WorkflowQuickActionData>[
                    _WorkflowQuickActionData(
                      title: 'Build Managera',
                      subtitle: 'Kompletný Windows build',
                      icon: Icons.build_circle_rounded,
                      onPressed: _managerBuildRunning || _managerProjectPath == null
                          ? null
                          : _buildReleaseManagerWindows,
                    ),
                    _WorkflowQuickActionData(
                      title: 'Export Release',
                      subtitle: 'Vytvoriť finálny ZIP',
                      icon: Icons.archive_rounded,
                      onPressed: _managerPublishing ||
                              _managerBuildRunning ||
                              !_managerBuildSucceeded
                          ? null
                          : _exportManagerReleasePackage,
                    ),
                    _WorkflowQuickActionData(
                      title: 'Test aplikácie',
                      subtitle: 'Spustiť hotové EXE',
                      icon: Icons.play_circle_fill_rounded,
                      onPressed: _managerBuildSucceeded ? _launchFinishedManagerApplication : null,
                    ),
                    _WorkflowQuickActionData(
                      title: 'GitHub Release',
                      subtitle: 'Publikovať vydanie',
                      icon: Icons.cloud_upload_rounded,
                      onPressed: _managerPublishing ||
                              _managerBuildRunning ||
                              _managerPackagePath == null
                          ? null
                          : _publishReleaseManager,
                    ),
                  ],
                ),
              if (_selectedPage == 5)
                const SizedBox(height: 12),
              if (_selectedPage == 5)
                Builder(
                  builder: (context) {
                    final completedSteps = <bool>[
                      _managerProjectPath != null,
                      _managerBuildSucceeded,
                      _managerPackagePath != null,
                      _managerPublished,
                      _managerApplicationLaunched,
                    ];
                    final requiredCompletedCount = <bool>[
                      completedSteps[0],
                      completedSteps[1],
                      completedSteps[2],
                      completedSteps[4],
                    ].where((value) => value).length;
                    final currentStepIndex = !completedSteps[0]
                        ? 0
                        : !completedSteps[1]
                            ? 1
                            : !completedSteps[2]
                                ? 2
                                : !completedSteps[4]
                                    ? 4
                                    : !completedSteps[3]
                                        ? 3
                                        : 4;
                    final workflowFinished = completedSteps[0] &&
                        completedSteps[1] &&
                        completedSteps[2] &&
                        completedSteps[4];
                    const workflowStepLabels = <String>[
                      'ZIP',
                      'Build',
                      'Export',
                      'Dokončiť vydanie',
                      'Test EXE',
                    ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.34),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.route_rounded,
                                    size: 20,
                                    color: Color(0xFF7C3AED),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      workflowFinished
                                          ? 'Release Wizard • povinný postup dokončený'
                                          : 'Release Wizard • ${workflowStepLabels[currentStepIndex]} (${currentStepIndex + 1} z 5)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(requiredCompletedCount / 4 * 100).round()} %',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              LinearProgressIndicator(
                                color: const Color(0xFF7C3AED),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(6),
                                value: requiredCompletedCount / 4,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: List<Widget>.generate(5, (index) {
                                  final done = completedSteps[index];
                                  final active = !workflowFinished && index == currentStepIndex;
                                  final color = done
                                      ? const Color(0xFF16A34A)
                                      : active
                                          ? const Color(0xFF7C3AED)
                                          : Theme.of(context).colorScheme.outline;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: active || done ? 0.10 : 0.03),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: color.withValues(alpha: 0.40)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(
                                          done
                                              ? Icons.check_circle
                                              : active
                                                  ? Icons.play_circle_fill
                                                  : Icons.radio_button_unchecked,
                                          size: 15,
                                          color: color,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '${index + 1}. ${workflowStepLabels[index]}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _WorkflowStepCard(
                          number: 1,
                          title: 'Rozbaliť ZIP',
                          description:
                              'Vyber ZIP novej verzie. Quick Build ho rozbalí, načíta projekt a automaticky spustí kompletný Windows build.',
                          icon: Icons.folder_zip_rounded,
                          completed: completedSteps[0],
                          active: !workflowFinished && currentStepIndex == 0,
                          running: _zipExtracting,
                          locked: false,
                          resultText: _managerProjectPath == null
                              ? null
                              : 'Pripravený projekt: ${path.basename(_managerProjectPath!)}',
                          secondaryAction: OutlinedButton.icon(
                            key: const Key('openZipButton'),
                            onPressed: _zipExtracting || _managerBuildRunning || _managerPublishing
                                ? null
                                : _openAndExtractZip,
                            icon: const Icon(Icons.folder_open_rounded),
                            label: const Text('LEN ROZBALIŤ ZIP'),
                          ),
                          action: FilledButton.icon(
                            onPressed: _zipExtracting || _managerBuildRunning || _managerPublishing
                                ? null
                                : () => _openAndExtractZip(startBuildAfterExtract: true),
                            icon: _zipExtracting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.rocket_launch_outlined),
                            label: Text(
                              _zipExtracting
                                  ? 'ROZBAĽUJEM ZIP...'
                                  : 'QUICK BUILD – ZIP + WINDOWS BUILD',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _WorkflowStepCard(
                          number: 2,
                          title: 'Build Release Managera',
                          description:
                              'Vykoná flutter clean, pub get, analyze, test a Windows release build.',
                          icon: Icons.build_circle_rounded,
                          completed: completedSteps[1],
                          active: !workflowFinished && currentStepIndex == 1,
                          running: _managerBuildRunning,
                          locked: !completedSteps[1] && currentStepIndex < 1,
                          resultText: _managerBuildSucceeded
                              ? 'Windows build bol úspešne dokončený.'
                              : _managerProjectPath,
                          secondaryAction: OutlinedButton.icon(
                            onPressed: _managerBuildRunning ? null : _selectManagerProjectDirectory,
                            icon: const Icon(Icons.folder_open),
                            label: Text(
                              _managerProjectPath == null
                                  ? 'VYBRAŤ PROJEKT'
                                  : path.basename(_managerProjectPath!),
                            ),
                          ),
                          action: FilledButton.icon(
                            key: const Key('buildReleaseManagerButton'),
                            onPressed: _managerBuildRunning || _managerProjectPath == null
                                ? null
                                : _buildReleaseManagerWindows,
                            icon: _managerBuildRunning
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.build_circle_outlined),
                            label: Text(
                              _managerBuildRunning
                                  ? 'PREBIEHA BUILD...'
                                  : 'SPUSTIŤ KOMPLETNÝ WINDOWS BUILD',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _WorkflowStepCard(
                          number: 3,
                          title: 'Export Release',
                          description:
                              'Zbalí obsah Windows Release priečinka a vytvorí finálny ZIP pripravený na publikovanie.',
                          icon: Icons.archive_rounded,
                          completed: completedSteps[2],
                          active: !workflowFinished && currentStepIndex == 2,
                          running: _managerPublishing && !_managerPublished,
                          locked: !completedSteps[2] && currentStepIndex < 2,
                          resultText: _managerPackagePath == null
                              ? _managerReleaseDirectoryPath
                              : 'Vytvorený ZIP: ${_managerPackagePath!}',
                          secondaryAction: OutlinedButton.icon(
                            onPressed: _managerPublishing || _managerBuildRunning
                                ? null
                                : _selectManagerReleaseDirectory,
                            icon: const Icon(Icons.folder_open),
                            label: Text(
                              _managerReleaseDirectoryPath == null
                                  ? 'VYBRAŤ WINDOWS RELEASE'
                                  : path.basename(_managerReleaseDirectoryPath!),
                            ),
                          ),
                          action: FilledButton.icon(
                            onPressed: _managerPublishing ||
                                    _managerBuildRunning ||
                                    !_managerBuildSucceeded
                                ? null
                                : _exportManagerReleasePackage,
                            icon: _managerPublishing
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.archive_outlined),
                            label: const Text('EXPORTOVAŤ RELEASE ZIP'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _WorkflowStepCard(
                          number: 4,
                          title: 'Dokončiť vydanie',
                          description:
                              'Otvorí Build Completion Center. Na jednom mieste doplníš Commit Message, popis zmien a zvolíš Commit, Push, Tag, ZIP, report a históriu.',
                          icon: Icons.task_alt_rounded,
                          completed: completedSteps[3],
                          active: !workflowFinished && currentStepIndex == 3,
                          running: false,
                          locked: _gitWorkspaceStatus?.isRepository != true,
                          resultText: _gitWorkspaceStatus?.isRepository == true
                              ? 'Git workspace je pripravený na dokončenie vydania.'
                              : 'Najprv vyber platný Git workspace projektu.',
                          secondaryAction: OutlinedButton.icon(
                            onPressed: () => setState(() => _selectedPage = 4),
                            icon: const Icon(Icons.cloud_outlined),
                            label: const Text('GITHUB A AKTUALIZÁCIE'),
                          ),
                          action: FilledButton.icon(
                            key: const Key('releaseWizardBuildCompletionButton'),
                            onPressed: _gitWorkspaceStatus?.isRepository == true
                                ? _showBuildCompletionCenter
                                : null,
                            icon: const Icon(Icons.task_alt_rounded),
                            label: const Text('DOKONČIŤ VYDANIE'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _WorkflowStepCard(
                          number: 5,
                          title: 'Otestovať hotovú aplikáciu',
                          description:
                              'Spustí skompilovaný EXE súbor, aby bolo možné finálnu verziu priamo vyskúšať.',
                          icon: Icons.play_circle_fill_rounded,
                          completed: completedSteps[4],
                          active: !workflowFinished && currentStepIndex == 4,
                          running: false,
                          locked: !_managerBuildSucceeded,
                          resultText: _managerApplicationLaunched
                              ? 'Hotová aplikácia bola úspešne spustená.'
                              : null,
                          secondaryAction: _managerReleaseDirectoryPath == null
                              ? null
                              : OutlinedButton.icon(
                                  onPressed: _openManagerReleaseDirectory,
                                  icon: const Icon(Icons.folder_open),
                                  label: const Text('OTVORIŤ RELEASE PRIEČINOK'),
                                ),
                          action: FilledButton.icon(
                            onPressed: _managerBuildSucceeded
                                ? _launchFinishedManagerApplication
                                : null,
                            icon: const Icon(Icons.play_circle_fill),
                            label: const Text('SPUSTIŤ HOTOVÚ APLIKÁCIU'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),

              if (_selectedPage == 5)
                RMSectionCard(
                title: 'Živý terminál',
                child: Container(
                  key: const Key('terminalOutput'),
                  height: 360,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.terminal, color: Colors.white70),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _activeCommand == null
                                  ? 'Terminál je pripravený'
                                  : 'Práve beží: $_activeCommand',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _busy ? null : () => setState(_diagnostics.clear),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('VYMAZAŤ'),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24),
                      Expanded(
                        child: Scrollbar(
                          controller: _terminalScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _terminalScrollController,
                            child: SelectableText(
                              _logs.join('\n'),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedPage == 6) _buildGitWorkspaceSection(),
              if (_selectedPage == 7)
                SizedBox(
                  height: MediaQuery.sizeOf(context).height - 92,
                  child: PluginMarketplacePage(
                    controller: _pluginMarketplaceController,
                    currentApiVersion: '1.0',
                  ),
                ),
              if (_selectedPage == 8)
                SizedBox(
                  height: MediaQuery.sizeOf(context).height - 92,
                  child: ReleasePipelineDesignerPage(
                    controller: _pipelineDesignerController,
                    executionController: _pipelineExecutionController,
                    workingDirectory: _managerProjectPath,
                  ),
                ),
              if (_selectedPage == 9)
                const RemoteAgentsPage(),
                  ],
                ),
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}


const String _demoMarketplaceJson = r'''
{
  "schemaVersion": 1,
  "generatedAt": "2026-07-31T12:00:00Z",
  "plugins": [
    {
      "id": "stavby.windows-build-optimizer",
      "name": "Windows Build Optimizer",
      "author": "STAVBY PRO",
      "version": "1.2.0",
      "apiVersion": "1.0",
      "minimumReleaseManagerVersion": "6.4.9",
      "downloadUrl": "https://plugins.stavby.pro/windows-build-optimizer.zip",
      "sha256": "1111111111111111111111111111111111111111111111111111111111111111",
      "description": "Optimalizuje prípravu Windows release buildu a kontroluje výstupné súbory.",
      "categories": [
        "Windows",
        "Build"
      ]
    },
    {
      "id": "stavby.android-apk-signer",
      "name": "Android APK Signer",
      "author": "STAVBY PRO",
      "version": "1.0.3",
      "apiVersion": "1.0",
      "minimumReleaseManagerVersion": "6.4.9",
      "downloadUrl": "https://plugins.stavby.pro/android-apk-signer.zip",
      "sha256": "2222222222222222222222222222222222222222222222222222222222222222",
      "description": "Pomocník na kontrolu podpisu APK a AAB balíčkov pred publikovaním.",
      "categories": [
        "Android",
        "Security"
      ]
    },
    {
      "id": "stavby.flutter-analyze-plus",
      "name": "Flutter Analyze+",
      "author": "STAVBY PRO",
      "version": "2.1.0",
      "apiVersion": "1.0",
      "minimumReleaseManagerVersion": "6.4.9",
      "downloadUrl": "https://plugins.stavby.pro/flutter-analyze-plus.zip",
      "sha256": "3333333333333333333333333333333333333333333333333333333333333333",
      "description": "Rozšírený prehľad výsledkov flutter analyze s filtrovaním a exportom reportu.",
      "categories": [
        "Flutter",
        "Diagnostika"
      ]
    },
    {
      "id": "stavby.github-release-publisher",
      "name": "GitHub Release Publisher",
      "author": "STAVBY PRO",
      "version": "1.4.1",
      "apiVersion": "1.0",
      "minimumReleaseManagerVersion": "6.4.9",
      "downloadUrl": "https://plugins.stavby.pro/github-release-publisher.zip",
      "sha256": "4444444444444444444444444444444444444444444444444444444444444444",
      "description": "Pripraví release poznámky a pomôže publikovať artefakty na GitHub.",
      "categories": [
        "GitHub",
        "Release"
      ]
    },
    {
      "id": "stavby.zip-export-assistant",
      "name": "ZIP Export Assistant",
      "author": "STAVBY PRO",
      "version": "1.1.2",
      "apiVersion": "1.0",
      "minimumReleaseManagerVersion": "6.4.9",
      "downloadUrl": "https://plugins.stavby.pro/zip-export-assistant.zip",
      "sha256": "5555555555555555555555555555555555555555555555555555555555555555",
      "description": "Kontroluje názov, koreňový adresár a obsah exportovaného release ZIP archívu.",
      "categories": [
        "Export",
        "Release"
      ]
    }
  ]
}
''';

class _WorkflowStepCard extends StatelessWidget {
  const _WorkflowStepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.completed,
    required this.active,
    required this.running,
    required this.locked,
    required this.action,
    this.secondaryAction,
    this.resultText,
  });

  final int number;
  final String title;
  final String description;
  final IconData icon;
  final bool completed;
  final bool active;
  final bool running;
  final bool locked;
  final Widget action;
  final Widget? secondaryAction;
  final String? resultText;

  @override
  Widget build(BuildContext context) {
    const Color wizardAccent = Color(0xFF7C3AED);
    final color = completed
        ? const Color(0xFF2E7D32)
        : active
            ? wizardAccent
            : wizardAccent.withValues(alpha: 0.62);
    final status = completed
        ? 'Dokončené'
        : running
            ? 'Prebieha'
            : active
                ? 'Čaká na akciu'
                : locked
                ? 'Uzamknuté'
                : 'Čaká';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: completed
            ? color.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: active ? 0.70 : 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: completed
                    ? Icon(Icons.check_rounded, color: color, size: 21)
                    : running
                        ? const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            active ? icon : Icons.schedule_rounded,
                            color: color,
                            size: 20,
                          ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      completed
                          ? Icons.check_circle
                          : running
                              ? Icons.sync_rounded
                              : active
                                  ? Icons.touch_app_rounded
                                  : locked
                                      ? Icons.lock_outline
                                      : Icons.schedule,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (secondaryAction != null) ...<Widget>[
                secondaryAction!,
                const SizedBox(width: 8),
              ],
              action,
            ],
          ),
          if (resultText != null && resultText!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 7),
            Row(
              children: <Widget>[
                Icon(completed ? Icons.check_circle_outline : Icons.info_outline, color: color, size: 17),
                const SizedBox(width: 7),
                Expanded(
                  child: SelectableText(
                    resultText!,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReleaseWizardPipeline extends StatelessWidget {
  const _ReleaseWizardPipeline({
    required this.steps,
    required this.completedSteps,
    required this.currentStep,
    required this.running,
  });

  final List<String> steps;
  final List<String> completedSteps;
  final String currentStep;
  final bool running;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120 ? 5 : constraints.maxWidth >= 860 ? 4 : constraints.maxWidth >= 620 ? 2 : 1;
        final spacing = 10.0;
        final width = (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: steps.asMap().entries.map((entry) {
            final step = entry.value;
            final completed = completedSteps.contains(step);
            final active = running && currentStep == step;
            final color = completed
                ? const Color(0xFF2E7D32)
                : active
                    ? const Color(0xFF7C3AED)
                    : Theme.of(context).colorScheme.outline;
            return SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: completed || active ? 0.10 : 0.04),
                  borderRadius: BorderRadius.circular(RMDesign.cardRadius),
                  border: Border.all(color: color.withValues(alpha: 0.34)),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      completed
                          ? Icons.check_circle_rounded
                          : active
                              ? Icons.play_circle_fill_rounded
                              : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: color,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${entry.key + 1}. $step',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            completed ? 'HOTOVO' : active ? 'PREBIEHA' : 'ČAKÁ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ReleaseArtifactCard extends StatelessWidget {
  const _ReleaseArtifactCard({
    required this.width,
    required this.title,
    required this.path,
    required this.icon,
  });

  final double width;
  final String title;
  final String? path;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ready = path != null && path!.trim().isNotEmpty;
    final color = ready ? const Color(0xFF2E7D32) : Theme.of(context).colorScheme.outline;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: ready ? 0.08 : 0.035),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    ready ? path! : 'Zatiaľ nevytvorené',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ),
            ),
            Icon(
              ready ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
              size: 17,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowQuickActionData {
  const _WorkflowQuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onPressed;
}

class _WorkflowQuickActions extends StatelessWidget {
  const _WorkflowQuickActions({
    required this.accent,
    required this.actions,
  });

  final Color accent;
  final List<_WorkflowQuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820 ? 4 : constraints.maxWidth >= 520 ? 2 : 1;
        final spacing = 10.0;
        final width = (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions.map((item) {
            final enabled = item.onPressed != null;
            return SizedBox(
              width: width,
              child: Material(
                color: enabled
                    ? accent.withValues(alpha: 0.10)
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: item.onPressed,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: enabled
                            ? accent.withValues(alpha: 0.48)
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: enabled ? 0.16 : 0.07),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon, color: enabled ? accent : Colors.grey, size: 19),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: enabled ? null : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: enabled
                                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                          : Colors.grey,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded, color: enabled ? accent : Colors.grey, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ApkWorkflowStep extends StatelessWidget {
  const _ApkWorkflowStep({
    required this.number,
    required this.title,
    required this.detail,
    required this.action,
    this.completed = false,
    this.active = false,
    this.progress,
    this.accent = const Color(0xFF43A047),
  });

  final int number;
  final String title;
  final String detail;
  final Widget action;
  final bool completed;
  final bool active;
  final double? progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? accent
        : active
            ? accent
            : accent.withValues(alpha: 0.72);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: completed
            ? accent.withValues(alpha: 0.10)
            : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: active
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : completed
                    ? Icon(Icons.check_rounded, color: color, size: 21)
                    : Text(
                        '$number',
                        style: TextStyle(color: color, fontWeight: FontWeight.w800),
                      ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 1),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (progress != null) ...<Widget>[
                  const SizedBox(height: 3),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          action,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
