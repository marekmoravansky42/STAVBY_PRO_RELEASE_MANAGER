class RemoteAgent {
  const RemoteAgent({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.operatingSystem,
    required this.flutterVersion,
    required this.platforms,
    required this.status,
    required this.lastSeen,
    required this.protocolVersion,
    required this.capabilities,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final String operatingSystem;
  final String flutterVersion;
  final List<String> platforms;
  final String status;
  final DateTime lastSeen;
  final int protocolVersion;
  final List<String> capabilities;

  bool get supportsAnalyze =>
      protocolVersion >= 2 && capabilities.contains('flutter_analyze');

  bool get supportsTest =>
      protocolVersion >= 3 && capabilities.contains('flutter_test');

  bool get supportsWindowsBuild =>
      protocolVersion >= 4 && capabilities.contains('flutter_build_windows');

  bool get isOnline => DateTime.now().difference(lastSeen) < const Duration(seconds: 12);

  factory RemoteAgent.fromJson(Map<String, dynamic> json, {required String host, required int port}) {
    return RemoteAgent(
      id: json['id']?.toString() ?? '$host:$port',
      name: json['name']?.toString() ?? host,
      host: host,
      port: port,
      operatingSystem: json['operatingSystem']?.toString() ?? 'Neznámy OS',
      flutterVersion: json['flutterVersion']?.toString() ?? 'Nezistené',
      platforms: (json['platforms'] as List<dynamic>? ?? const <dynamic>[]).map((e) => e.toString()).toList(growable: false),
      status: json['status']?.toString() ?? 'idle',
      lastSeen: DateTime.now(),
      protocolVersion: json['protocolVersion'] is num
          ? (json['protocolVersion'] as num).toInt()
          : 1,
      capabilities: (json['capabilities'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }
}
