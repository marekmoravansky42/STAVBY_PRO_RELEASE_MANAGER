import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/release_pipeline/default_templates.dart';
import '../../core/release_pipeline/pipeline_step.dart';
import '../../core/release_pipeline/pipeline_storage.dart';
import '../../core/release_pipeline/pipeline_template.dart';
import '../../core/release_pipeline/pipeline_validator.dart';

/// State controller for the universal Release Pipeline Designer.
class ReleasePipelineDesignerController extends ChangeNotifier {
  ReleasePipelineDesignerController({PipelineStorage? storage})
      : _storage = storage ?? PipelineStorage();

  final PipelineStorage _storage;
  final PipelineValidator _validator = const PipelineValidator();

  List<PipelineTemplate> _templates = const <PipelineTemplate>[];
  String? _selectedId;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  List<PipelineTemplate> get templates => _templates;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  String? get selectedId => _selectedId;

  PipelineTemplate? get selectedTemplate {
    for (final template in _templates) {
      if (template.id == _selectedId) return template;
    }
    return _templates.isEmpty ? null : _templates.first;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final stored = await _storage.load();
      _templates = stored.isEmpty
          ? List<PipelineTemplate>.from(DefaultPipelineTemplates.all)
          : List<PipelineTemplate>.from(stored);
      final savedSelectedId = await _storage.loadSelectedId();
      _selectedId = savedSelectedId != null &&
              _templates.any((template) => template.id == savedSelectedId)
          ? savedSelectedId
          : _initialSelectedId(_templates);
      if (stored.isEmpty) await _storage.save(_templates);
      if (_selectedId != null) {
        // The initial selection is part of load(). Wait for persistence to
        // finish so tests and callers cannot dispose the workspace while the
        // state file is still being written.
        await _storage.saveSelectedId(_selectedId!);
      }
    } catch (error) {
      _error = 'Pipeline sa nepodarilo načítať: $error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String? _initialSelectedId(List<PipelineTemplate> templates) {
    if (templates.isEmpty) return null;
    for (final template in templates) {
      if (template.isDefault) return template.id;
    }
    return templates.first.id;
  }

  void select(String id) {
    if (_templates.any((template) => template.id == id)) {
      _selectedId = id;
      unawaited(_storage.saveSelectedId(id));
      notifyListeners();
    }
  }

  void toggleStep(String stepId, bool enabled) {
    _updateSelected((template) {
      final steps = template.steps
          .map((step) => step.id == stepId ? step.copyWith(enabled: enabled) : step)
          .toList(growable: false);
      return template.copyWith(steps: steps, updatedAt: DateTime.now());
    });
  }

  void moveStep(String stepId, int delta) {
    _updateSelected((template) {
      final steps = List<PipelineStep>.from(template.steps);
      final index = steps.indexWhere((step) => step.id == stepId);
      if (index < 0) return template;
      final target = index + delta;
      if (target < 0 || target >= steps.length) return template;
      final step = steps.removeAt(index);
      steps.insert(target, step);
      return template.copyWith(steps: steps, updatedAt: DateTime.now());
    });
  }

  Future<bool> save() async {
    final selected = selectedTemplate;
    if (selected == null) return false;
    final validation = _validator.validate(selected);
    if (!validation.isValid) {
      _error = validation.errors.join('\n');
      notifyListeners();
      return false;
    }
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _storage.save(_templates);
      return true;
    } catch (error) {
      _error = 'Pipeline sa nepodarilo uložiť: $error';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  void resetToDefaults() {
    _templates = List<PipelineTemplate>.from(DefaultPipelineTemplates.all);
    _selectedId = _templates.first.id;
    unawaited(_storage.saveSelectedId(_selectedId!));
    _error = null;
    notifyListeners();
  }

  void _updateSelected(PipelineTemplate Function(PipelineTemplate) update) {
    final id = _selectedId;
    if (id == null) return;
    _templates = _templates
        .map((template) => template.id == id ? update(template) : template)
        .toList(growable: false);
    notifyListeners();
  }
}
