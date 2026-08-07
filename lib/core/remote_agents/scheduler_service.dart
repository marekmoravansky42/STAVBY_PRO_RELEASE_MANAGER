import 'remote_agent.dart';

class SchedulerValidation {
  const SchedulerValidation({required this.isValid, required this.message});

  final bool isValid;
  final String message;
}

class SchedulerService {
  const SchedulerService();

  RemoteAgent? selectBest(Iterable<RemoteAgent> agents, String taskType) {
    final candidates = agents
        .where((agent) => validate(agent, taskType).isValid)
        .toList(growable: false);
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final aBusy = a.status == 'busy' ? 1 : 0;
      final bBusy = b.status == 'busy' ? 1 : 0;
      final busy = aBusy.compareTo(bBusy);
      if (busy != 0) return busy;
      final heartbeat = b.lastSeen.compareTo(a.lastSeen);
      if (heartbeat != 0) return heartbeat;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return candidates.first;
  }

  SchedulerValidation validate(RemoteAgent? agent, String taskType) {
    if (agent == null) {
      return const SchedulerValidation(
        isValid: false,
        message: 'Pre krok nie je vybraný žiadny agent.',
      );
    }
    if (!agent.isOnline) {
      return SchedulerValidation(
        isValid: false,
        message: 'Agent ${agent.name} je offline alebo má neaktuálny heartbeat.',
      );
    }
    if (agent.status == 'busy') {
      return SchedulerValidation(
        isValid: false,
        message: 'Agent ${agent.name} práve vykonáva inú úlohu.',
      );
    }

    final supported = switch (taskType) {
      'test' => agent.supportsTest,
      'windowsBuild' => agent.supportsWindowsBuild,
      _ => agent.supportsAnalyze,
    };
    if (!supported) {
      return SchedulerValidation(
        isValid: false,
        message: 'Agent ${agent.name} nepodporuje požadovaný krok.',
      );
    }
    return const SchedulerValidation(isValid: true, message: 'Agent je pripravený.');
  }
}
