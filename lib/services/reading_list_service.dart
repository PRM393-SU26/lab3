import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/work.dart';

class ReadingListService {
  String get _key {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'guest';
    return 'reading_list_$uid';
  }

  Future<List<Work>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => _workFromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(Work work) async {
    final items = await getAll();
    if (items.any((w) => w.id == work.id)) return;

    items.add(work);
    await _persist(items);
  }

  Future<void> remove(String workId) async {
    final items = await getAll();
    items.removeWhere((w) => w.id == workId);
    await _persist(items);
  }

  Future<bool> contains(String workId) async {
    final items = await getAll();
    return items.any((w) => w.id == workId);
  }

  Future<void> _persist(List<Work> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map(_workToJson).toList());
    await prefs.setString(_key, encoded);
  }

  Map<String, dynamic> _workToJson(Work work) {
    return {
      'id': work.id,
      'title': work.title,
      'publicationYear': work.publicationYear,
      'citedByCount': work.citedByCount,
      'doi': work.doi,
      'isOpenAccess': work.isOpenAccess,
      'type': work.type,
      'primarySourceName': work.primarySource?.displayName,
    };
  }

  Work _workFromJson(Map<String, dynamic> json) {
    final sourceName = json['primarySourceName'] as String?;
    return Work(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      publicationYear: json['publicationYear'] as int?,
      citedByCount: json['citedByCount'] as int? ?? 0,
      doi: json['doi'] as String?,
      isOpenAccess: json['isOpenAccess'] as bool? ?? false,
      authorships: const [],
      primarySource: sourceName != null
          ? Source(displayName: sourceName)
          : null,
      type: json['type'] as String?,
    );
  }
}
