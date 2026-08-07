import 'remote_agent.dart';

class AgentPool {
  final Map<String, RemoteAgent> _agents = <String, RemoteAgent>{};

  List<RemoteAgent> get agents {
    final values = _agents.values.toList(growable: false);
    values.sort((a, b) {
      final online = (b.isOnline ? 1 : 0).compareTo(a.isOnline ? 1 : 0);
      if (online != 0) return online;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return values;
  }

  RemoteAgent? getById(String? id) => id == null ? null : _agents[id];

  void upsert(RemoteAgent agent) => _agents[agent.id] = agent;

  void remove(String id) => _agents.remove(id);

  void clear() => _agents.clear();

  bool get isEmpty => _agents.isEmpty;
}
