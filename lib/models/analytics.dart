/// One bar in the "publications per year" chart
class YearlyCount {
  final int year;
  final int count;
  YearlyCount({required this.year, required this.count});
}

/// One entry in the Top Journals list
class JournalStat {
  final String? sourceId;
  final String displayName;
  final int paperCount;
  final int hIndex;
  final int citationCount;
  JournalStat({
    this.sourceId,
    required this.displayName,
    required this.paperCount,
    this.hIndex = 0,
    this.citationCount = 0,
  });
}

/// One entry in the Top Authors list
class AuthorStat {
  final String? authorId;
  final String displayName;
  final int paperCount;
  AuthorStat({this.authorId, required this.displayName, required this.paperCount});
}

/// Summary for the Research Dashboard screen
class TopicDashboard {
  final String topic;
  final int totalPublications;
  final double avgCitationCount;
  final int? peakYear;
  final int? peakYearCount;
  final double openAccessRatio;
  final String? topJournalName;
  final String? topAuthorName;
  final String? topAuthorInstitution;
  final String? mostInfluentialTitle;
  final int? mostInfluentialCitations;

  TopicDashboard({
    required this.topic,
    required this.totalPublications,
    required this.avgCitationCount,
    this.peakYear,
    this.peakYearCount,
    required this.openAccessRatio,
    this.topJournalName,
    this.topAuthorName,
    this.topAuthorInstitution,
    this.mostInfluentialTitle,
    this.mostInfluentialCitations,
  });
}

/// Matrix containing paper count by Country and Topic (Field)
class CountryTopicMatrix {
  final List<String> countries; // Display names of countries, e.g. ["United States", "China"]
  final List<String> countryCodes; // Codes of countries, e.g. ["US", "CN"]
  final List<String> topics; // Display names of topics, e.g. ["Computer Science", "Physics"]
  final Map<String, Map<String, int>> data; // Map of countryCode -> {topicName: paperCount}

  CountryTopicMatrix({
    required this.countries,
    required this.countryCodes,
    required this.topics,
    required this.data,
  });

  factory CountryTopicMatrix.empty() {
    return CountryTopicMatrix(
      countries: [],
      countryCodes: [],
      topics: [],
      data: {},
    );
  }

  bool get isEmpty => countries.isEmpty;
  bool get isNotEmpty => countries.isNotEmpty;
}

/// One entry in the Top Keywords/Concepts list
class KeywordStat {
  final String? conceptId;
  final String displayName;
  final int paperCount;

  KeywordStat({
    this.conceptId,
    required this.displayName,
    required this.paperCount,
  });
}

/// A taxonomy item (Domain, Field, or Subfield) from OpenAlex
class TaxonomyItem {
  final String id;
  final String displayName;
  
  TaxonomyItem({required this.id, required this.displayName});

  factory TaxonomyItem.fromJson(Map<String, dynamic> json) {
    return TaxonomyItem(
      id: json['id'].toString().split('/').last,
      displayName: json['display_name'] ?? 'Unknown',
    );
  }
}
