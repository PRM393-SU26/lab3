class Work {
  final String id;
  final String title;
  final int? publicationYear;
  final int citedByCount;
  final String? doi;
  final String? abstractText;
  final bool isOpenAccess;
  final List<Authorship> authorships;
  final Source? primarySource;
  final String? type;

  Work({
    required this.id,
    required this.title,
    this.publicationYear,
    required this.citedByCount,
    this.doi,
    this.abstractText,
    required this.isOpenAccess,
    required this.authorships,
    this.primarySource,
    this.type,
  });

  factory Work.fromJson(Map<String, dynamic> json) {
    // Reconstruct abstract from inverted index
    String? abstract;
    final invertedIndex = json['abstract_inverted_index'];
    if (invertedIndex != null && invertedIndex is Map) {
      abstract = _reconstructAbstract(Map<String, List<int>>.from(
        invertedIndex.map((k, v) => MapEntry(k, List<int>.from(v))),
      ));
    }

    return Work(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      publicationYear: json['publication_year'],
      citedByCount: json['cited_by_count'] ?? 0,
      doi: json['doi'],
      abstractText: abstract,
      isOpenAccess: json['open_access']?['is_oa'] ?? false,
      authorships: (json['authorships'] as List? ?? [])
          .map((a) => Authorship.fromJson(a))
          .toList(),
      primarySource: json['primary_location']?['source'] != null
          ? Source.fromJson(json['primary_location']['source'])
          : null,
      type: json['type'],
    );
  }

  static String _reconstructAbstract(Map<String, List<int>> invertedIndex) {
    final wordPositions = <int, String>{};
    invertedIndex.forEach((word, positions) {
      for (final pos in positions) {
        wordPositions[pos] = word;
      }
    });
    final sorted = wordPositions.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((e) => e.value).join(' ');
  }
}

class Authorship {
  final String? authorId;
  final String authorName;
  final String? institutionName;

  Authorship({
    this.authorId,
    required this.authorName,
    this.institutionName,
  });

  factory Authorship.fromJson(Map<String, dynamic> json) {
    final institutions = json['institutions'] as List? ?? [];
    return Authorship(
      authorId: json['author']?['id'],
      authorName: json['author']?['display_name'] ?? 'Unknown',
      institutionName: institutions.isNotEmpty
          ? institutions.first['display_name']
          : null,
    );
  }
}

class Source {
  final String? id;
  final String displayName;
  final String? type;

  Source({this.id, required this.displayName, this.type});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id'],
      displayName: json['display_name'] ?? 'Unknown',
      type: json['type'],
    );
  }
}
