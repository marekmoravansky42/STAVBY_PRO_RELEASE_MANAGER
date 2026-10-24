class FinalPublicationChangeLogSection {
  const FinalPublicationChangeLogSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;
}

List<String> normalizeFinalPublicationChangeLog(String text) => text
    .split(RegExp(r'\r?\n'))
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .map((line) => line.replaceFirst(RegExp(r'^[-•*]\s*'), '').trim())
    .where((line) => line.isNotEmpty)
    .toList(growable: false);

List<FinalPublicationChangeLogSection> finalPublicationChangeLogSections(
  Map<String, dynamic> record,
) {
  List<String> itemsFor(String key) {
    final raw = record[key];
    if (raw is! List) return const <String>[];
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  final news = itemsFor('news');
  final fixes = itemsFor('fixes');
  return <FinalPublicationChangeLogSection>[
    if (news.isNotEmpty)
      FinalPublicationChangeLogSection(title: 'Novinky', items: news),
    if (fixes.isNotEmpty)
      FinalPublicationChangeLogSection(title: 'Opravy', items: fixes),
  ];
}
