/// Author profile returned by GET /authors/{id}
class AuthorDetail {
  final String id;
  final String displayName;
  final String? orcid;
  final int worksCount;
  final int citedByCount;
  final int hIndex;
  final int i10Index;
  final String? lastInstitutionName;
  final String? lastInstitutionCountry;

  AuthorDetail({
    required this.id,
    required this.displayName,
    this.orcid,
    required this.worksCount,
    required this.citedByCount,
    required this.hIndex,
    required this.i10Index,
    this.lastInstitutionName,
    this.lastInstitutionCountry,
  });

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  factory AuthorDetail.fromJson(Map<String, dynamic> json) {
    final stats = json['summary_stats'] as Map<String, dynamic>? ?? {};
    final institutions = json['last_known_institutions'] as List? ?? [];
    final inst = institutions.isNotEmpty
        ? institutions.first as Map<String, dynamic>
        : null;

    return AuthorDetail(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? 'Unknown',
      orcid: json['orcid'],
      worksCount: _asInt(json['works_count']),
      citedByCount: _asInt(json['cited_by_count']),
      hIndex: _asInt(stats['h_index']),
      i10Index: _asInt(stats['i10_index']),
      lastInstitutionName: inst?['display_name'],
      lastInstitutionCountry: inst?['country_code'],
    );
  }
}

/// Journal/source profile returned by GET /sources/{id}
class SourceDetail {
  final String id;
  final String displayName;
  final String? type;
  final int worksCount;
  final int citedByCount;
  final int hIndex;
  final bool isOa;
  final bool isInDoaj;
  final String? countryCode;
  final String? homepageUrl;

  SourceDetail({
    required this.id,
    required this.displayName,
    this.type,
    required this.worksCount,
    required this.citedByCount,
    required this.hIndex,
    required this.isOa,
    required this.isInDoaj,
    this.countryCode,
    this.homepageUrl,
  });

  factory SourceDetail.fromJson(Map<String, dynamic> json) {
    final stats = json['summary_stats'] as Map<String, dynamic>? ?? {};
    return SourceDetail(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? 'Unknown',
      type: json['type'],
      worksCount: AuthorDetail._asInt(json['works_count']),
      citedByCount: AuthorDetail._asInt(json['cited_by_count']),
      hIndex: AuthorDetail._asInt(stats['h_index']),
      isOa: json['is_oa'] ?? false,
      isInDoaj: json['is_in_doaj'] ?? false,
      countryCode: json['country_code'],
      homepageUrl: json['homepage_url'],
    );
  }
}

/// One entry in the country breakdown chart
class CountryStat {
  final String countryCode;
  final String displayName;
  final int paperCount;
  CountryStat({
    required this.countryCode,
    required this.displayName,
    required this.paperCount,
  });
}

/// One entry in the OA status breakdown (gold/green/hybrid/bronze/closed)
class OaStat {
  final String status;
  final int count;
  OaStat({required this.status, required this.count});
}
