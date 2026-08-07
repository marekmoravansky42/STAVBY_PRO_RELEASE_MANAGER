class AgentApi {
  const AgentApi._();

  static const int protocolVersion = 4;
  static const int defaultPort = 47834;

  static const String status = '/status';
  static const String ping = '/ping';
  static const String analyzeTasks = '/tasks/analyze';
  static const String testTasks = '/tasks/test';
  static const String windowsBuildTasks = '/tasks/build/windows';

  static String task(String id) => '/tasks/$id';
}
