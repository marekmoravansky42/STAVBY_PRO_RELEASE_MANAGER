/// Identifies only Flutter's SDK-cache lockfile access failure and supplies
/// a safe, manual recovery hint. It never changes the SDK or starts a process.
class FlutterSdkLockfileGuidance {
  static const List<String> _guidance = <String>[
    'Flutter SDK lockfile je nedostupný.',
    'Dokončite alebo zatvorte iné Flutter procesy.',
    'Overte právo zápisu do Flutter SDK cache.',
    'Spustite FAST DEV BUILD znova.',
  ];

  static bool isExactLockfileAccessError(Iterable<String> output) {
    final text = output.join('\n');
    return RegExp(
      r'''failed to open a file at\s+["']?[^"']*flutter[\\/]+bin[\\/]+cache[\\/]+lockfile(?:["']|\.|\s|$)''',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static List<String>? forOutput(Iterable<String> output) {
    return isExactLockfileAccessError(output)
        ? List<String>.unmodifiable(_guidance)
        : null;
  }
}
