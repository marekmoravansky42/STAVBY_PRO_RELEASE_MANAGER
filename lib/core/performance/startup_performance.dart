import 'dart:collection';

/// Lightweight startup timing collector.
///
/// The collector intentionally has no Flutter dependency, so it can be used by
/// bootstrap code and services without creating additional widget rebuilds.
abstract final class StartupPerformance {
  static final Stopwatch _stopwatch = Stopwatch()..start();
  static final LinkedHashMap<String, Duration> _milestones =
      LinkedHashMap<String, Duration>();

  static Duration get elapsed => _stopwatch.elapsed;

  static void mark(String name) {
    _milestones.putIfAbsent(name, () => _stopwatch.elapsed);
  }

  static Map<String, Duration> snapshot() =>
      Map<String, Duration>.unmodifiable(_milestones);

  static String summary() {
    if (_milestones.isEmpty) {
      return 'Štart aplikácie: ${elapsed.inMilliseconds} ms';
    }
    final parts = _milestones.entries
        .map((entry) => '${entry.key}: ${entry.value.inMilliseconds} ms')
        .join(' • ');
    return 'Štart aplikácie: $parts';
  }
}
