import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/plugin_configuration/plugin_configuration_manager.dart';
import '../../core/plugin_configuration/plugin_configuration_schema.dart';

class PluginConfigurationDialog extends StatefulWidget {
  const PluginConfigurationDialog({
    super.key,
    required this.manager,
    required this.schema,
    required this.pluginName,
  });

  final PluginConfigurationManager manager;
  final PluginConfigurationSchema schema;
  final String pluginName;

  static Future<bool?> show(
    BuildContext context, {
    required PluginConfigurationManager manager,
    required PluginConfigurationSchema schema,
    required String pluginName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PluginConfigurationDialog(
        manager: manager,
        schema: schema,
        pluginName: pluginName,
      ),
    );
  }

  @override
  State<PluginConfigurationDialog> createState() =>
      _PluginConfigurationDialogState();
}

class _PluginConfigurationDialogState extends State<PluginConfigurationDialog> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  final Map<String, bool> _booleanValues = <String, bool>{};

  bool _loading = true;
  bool _saving = false;
  List<String> _errors = const <String>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final result = await widget.manager.load(schema: widget.schema);
    if (!mounted) return;

    _replaceValues(result.configuration);
    setState(() {
      _loading = false;
      _errors = result.errors;
    });
  }

  void _replaceValues(Map<String, dynamic> values) {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _booleanValues.clear();

    for (final field in widget.schema.fields.values) {
      final value = values[field.key] ?? field.defaultValue;
      if (field.type == PluginConfigurationValueType.boolean) {
        _booleanValues[field.key] = value is bool ? value : false;
      } else {
        _controllers[field.key] = TextEditingController(
          text: _formatValue(field.type, value),
        );
      }
    }
  }

  String _formatValue(PluginConfigurationValueType type, Object? value) {
    if (value == null) return '';
    if (type == PluginConfigurationValueType.list ||
        type == PluginConfigurationValueType.map) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }
    return value.toString();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _errors = const <String>[];
    });

    final values = <String, dynamic>{};
    final conversionErrors = <String>[];
    for (final field in widget.schema.fields.values) {
      try {
        values[field.key] = _readValue(field);
      } on FormatException catch (error) {
        conversionErrors.add('${field.key}: ${error.message}');
      }
    }

    if (conversionErrors.isNotEmpty) {
      setState(() {
        _saving = false;
        _errors = conversionErrors;
      });
      return;
    }

    final result = await widget.manager.save(
      schema: widget.schema,
      values: values,
    );
    if (!mounted) return;

    if (result.isValid) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _saving = false;
      _errors = result.errors;
    });
  }

  Object? _readValue(PluginConfigurationField field) {
    if (field.type == PluginConfigurationValueType.boolean) {
      return _booleanValues[field.key] ?? false;
    }

    final text = _controllers[field.key]?.text.trim() ?? '';
    if (text.isEmpty && !field.required) return null;

    return switch (field.type) {
      PluginConfigurationValueType.string => text,
      PluginConfigurationValueType.integer =>
        int.tryParse(text) ?? (throw const FormatException('zadaj celé číslo')),
      PluginConfigurationValueType.decimal => double.tryParse(text) ??
          (throw const FormatException('zadaj platné číslo')),
      PluginConfigurationValueType.boolean => false,
      PluginConfigurationValueType.list => _decodeList(text),
      PluginConfigurationValueType.map => _decodeMap(text),
    };
  }

  List<dynamic> _decodeList(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! List<dynamic>) {
      throw const FormatException('hodnota musí byť JSON zoznam');
    }
    return decoded;
  }

  Map<String, dynamic> _decodeMap(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('hodnota musí byť JSON objekt');
    }
    return decoded;
  }

  Future<void> _reset() async {
    setState(() {
      _loading = true;
      _errors = const <String>[];
    });
    await widget.manager.reset(widget.schema.pluginId);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Konfigurácia – ${widget.pluginName}'),
      content: SizedBox(
        width: 560,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final field in widget.schema.fields.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ConfigurationFieldEditor(
                          field: field,
                          controller: _controllers[field.key],
                          booleanValue: _booleanValues[field.key],
                          onBooleanChanged: (value) {
                            setState(() {
                              _booleanValues[field.key] = value;
                            });
                          },
                        ),
                      ),
                    if (_errors.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Konfiguráciu nie je možné uložiť:',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              for (final error in _errors) Text('• $error'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _loading || _saving ? null : _reset,
          child: const Text('Obnoviť predvolené'),
        ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Zrušiť'),
        ),
        FilledButton(
          onPressed: _loading || _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Uložiť'),
        ),
      ],
    );
  }
}

class _ConfigurationFieldEditor extends StatelessWidget {
  const _ConfigurationFieldEditor({
    required this.field,
    required this.controller,
    required this.booleanValue,
    required this.onBooleanChanged,
  });

  final PluginConfigurationField field;
  final TextEditingController? controller;
  final bool? booleanValue;
  final ValueChanged<bool> onBooleanChanged;

  @override
  Widget build(BuildContext context) {
    final label = field.required ? '${field.key} *' : field.key;
    if (field.type == PluginConfigurationValueType.boolean) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: const Text('Zapnuté / vypnuté'),
        value: booleanValue ?? false,
        onChanged: onBooleanChanged,
      );
    }

    final multiline = field.type == PluginConfigurationValueType.list ||
        field.type == PluginConfigurationValueType.map;
    return TextField(
      controller: controller,
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? 8 : 1,
      keyboardType: switch (field.type) {
        PluginConfigurationValueType.integer => TextInputType.number,
        PluginConfigurationValueType.decimal =>
          const TextInputType.numberWithOptions(decimal: true, signed: true),
        _ => TextInputType.text,
      },
      decoration: InputDecoration(
        labelText: label,
        helperText: _typeLabel(field.type),
        border: const OutlineInputBorder(),
      ),
    );
  }

  String _typeLabel(PluginConfigurationValueType type) {
    return switch (type) {
      PluginConfigurationValueType.string => 'Text',
      PluginConfigurationValueType.integer => 'Celé číslo',
      PluginConfigurationValueType.decimal => 'Desatinné číslo',
      PluginConfigurationValueType.boolean => 'Áno / nie',
      PluginConfigurationValueType.list => 'JSON zoznam',
      PluginConfigurationValueType.map => 'JSON objekt',
    };
  }
}
