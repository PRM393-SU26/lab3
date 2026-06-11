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
  JournalStat({this.sourceId, required this.displayName, required this.paperCount});
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
