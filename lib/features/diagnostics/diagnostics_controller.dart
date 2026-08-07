import 'package:flutter/foundation.dart';

/// Centralizovaný stav živého terminálu a diagnostiky aplikácie.
class DiagnosticsController extends ChangeNotifier {
  DiagnosticsController({this.maximumEntries = 5000});

  final int maximumEntries;
  final List<String> _logs = <String>[];

  List<String> get logs => _logs;
  bool get hasLogs => _logs.isNotEmpty;

  void add(String message, {DateTime? timestamp}) {
    final now = timestamp ?? DateTime.now();
    _logs.add('${_formatTime(now)}  $message');
    if (_logs.length > maximumEntries) {
      _logs.removeRange(0, _logs.length - maximumEntries);
    }
    notifyListeners();
  }

  List<String> tail([int count = 100]) {
    if (count <= 0 || _logs.isEmpty) return const <String>[];
    final start = _logs.length > count ? _logs.length - count : 0;
    return List<String>.unmodifiable(_logs.sublist(start));
  }

  String exportText() => _logs.isEmpty ? '' : '${_logs.join('\n')}\n';

  void clear() {
    if (_logs.isEmpty) return;
    _logs.clear();
    notifyListeners();
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
